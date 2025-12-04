import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import UIKit

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        db.settings = settings
    }
    // MARK: - Security & Privacy
    
    func clearCache() async {
        do {
            try await db.clearPersistence()
        } catch {
            // Handle error silently
        }
    }
    
    // MARK: - Events
    
    func fetchApprovedEvents() async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("status", isEqualTo: EventStatus.approved.rawValue)
            .order(by: "eventDate", descending: false)
            .limit(to: 50) // Limit to save costs
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Event.self)
        }
    }
    
    func fetchPendingEvents() async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("status", isEqualTo: EventStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: 50) // Limit to save costs
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Event.self)
        }
    }
    
    func fetchUserEvents(userId: String) async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("createBy", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Event.self)
        }
    }
    
    func addEvent(_ event: Event) async throws {
        try db.collection("events").document(event.id).setData(from: event)
        
        // If event is pending, notify admins
        // If event is pending, notify admins
        if event.status == .pending {
            let notificationId = UUID().uuidString
            let notification = AppNotification(
                id: notificationId,
                userId: "ADMIN", // Special ID for admin notifications
                title: "New Event Request",
                message: "A new event '\(event.title)' is waiting for approval.",
                type: .info,
                isRead: false,
                createdAt: Date(),
                relatedItemId: event.id,
                relatedItemType: "event"
            )
            
            try db.collection("notifications").document(notificationId).setData(from: notification)
        }
    }
    
    func uploadImage(_ image: UIImage) async throws -> String {
        // 1. Resize image to avoid Firestore 1MB limit (Max 500px width)
        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 500, height: 500))
        
        // 2. Compress to JPEG
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.6) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        // 3. Convert to Base64 String
        let base64String = imageData.base64EncodedString()
        return "data:image/jpeg;base64,\(base64String)"
    }
    
    // Helper to resize image
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize: CGSize
        
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    func updateEventStatus(eventId: String, status: EventStatus) async throws {
        try await db.collection("events").document(eventId).updateData([
            "status": status.rawValue
        ])
    }
    
    func deleteEvent(eventId: String) async throws {
        try await db.collection("events").document(eventId).delete()
    }
    
    // MARK: - Notifications
    
    func fetchNotifications(userId: String) async throws -> [AppNotification] {
        let snapshot = try await db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 20) // Limit to save costs
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: AppNotification.self)
        }
    }
    
    func addNotification(_ notification: AppNotification) async throws {
        try db.collection("notifications").addDocument(from: notification)
    }
    
    func markNotificationAsRead(notificationId: String) async throws {
        try await db.collection("notifications").document(notificationId).updateData([
            "isRead": true
        ])
    }
    
    // MARK: - Event Participation & Interest
    
    func joinEvent(eventId: String, userId: String, details: [String: Any]) async throws {
        let data: [String: Any] = [
            "userId": userId,
            "joinedAt": Timestamp(date: Date()),
            "details": details
        ]
        
        let batch = db.batch()
        
        // 1. Add to 'participants' subcollection in Event
        let participantRef = db.collection("events").document(eventId).collection("participants").document(userId)
        batch.setData(data, forDocument: participantRef)
        
        // 2. Add to 'joinedEvents' subcollection in User (for My Events)
        let userEventRef = db.collection("users").document(userId).collection("joinedEvents").document(eventId)
        batch.setData(["joinedAt": Timestamp(date: Date())], forDocument: userEventRef)
        
        try await batch.commit()
    }
    
    func fetchJoinedEvents(userId: String) async throws -> [Event] {
        // 1. Get all event IDs the user has joined
        let snapshot = try await db.collection("users").document(userId).collection("joinedEvents").getDocuments()
        let eventIds = snapshot.documents.map { $0.documentID }
        
        if eventIds.isEmpty { return [] }
        
        // 2. Fetch actual event data
        var events: [Event] = []
        
        // Fetch sequentially to avoid actor isolation issues and complexity
        for eventId in eventIds {
            if let doc = try? await db.collection("events").document(eventId).getDocument(),
               let event = try? doc.data(as: Event.self) {
                events.append(event)
            }
        }
        
        return events.sorted(by: { $0.eventDate < $1.eventDate })
    }
    
    func checkIfJoined(eventId: String, userId: String) async throws -> Bool {
        let doc = try await db.collection("events").document(eventId).collection("participants").document(userId).getDocument()
        return doc.exists
    }
    
    func toggleInterest(eventId: String, userId: String) async throws -> Bool {
        let eventRef = db.collection("events").document(eventId)
        let docRef = eventRef.collection("interested").document(userId)
        
        let doc = try await docRef.getDocument()
        
        if doc.exists {
            try await docRef.delete()
            // Decrement count
            try await eventRef.updateData([
                "interestedCount": FieldValue.increment(Int64(-1))
            ])
            return false // No longer interested
        } else {
            try await docRef.setData(["interestedAt": Timestamp(date: Date())])
            // Increment count
            try await eventRef.updateData([
                "interestedCount": FieldValue.increment(Int64(1))
            ])
            return true // Now interested
        }
    }
    
    func checkIfInterested(eventId: String, userId: String) async throws -> Bool {
        let doc = try await db.collection("events").document(eventId).collection("interested").document(userId).getDocument()
        return doc.exists
    }
    
    func getInterestedCount(eventId: String) async throws -> Int {
        let snapshot = try await db.collection("events").document(eventId).collection("interested").getDocuments()
        return snapshot.count
    }
    
    // MARK: - Users
    
    func fetchUser(userId: String) async throws -> User? {
        let document = try await db.collection("users").document(userId).getDocument()
        return try? document.data(as: User.self)
    }
    
    func saveUser(_ user: User) async throws {
        try db.collection("users").document(user.id).setData(from: user)
    }
    
    func getDemoUserCount(role: UserRole) async throws -> Int {
        let prefix = role == .admin ? "admin@demo" : "student@demo"
        // Note: This is a simple count for demo purposes. 
        // In production with millions of users, use aggregation queries.
        let snapshot = try await db.collection("users")
            .whereField("email", isGreaterThanOrEqualTo: prefix)
            .whereField("email", isLessThan: prefix + "\u{f8ff}")
            .getDocuments()
        return snapshot.count
    }
    
    func fetchUserProfile(userId: String) async throws -> User? {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        return try? snapshot.data(as: User.self)
    }
    
    // MARK: - Report & Block
    func reportPost(postId: String, reason: String) async throws {
        let reportData: [String: Any] = [
            "postId": postId,
            "reason": reason,
            "reportedBy": Auth.auth().currentUser?.uid ?? "unknown",
            "createdAt": Timestamp(date: Date())
        ]
        try await db.collection("reports").addDocument(data: reportData)
    }
    
    func blockUser(userIdToBlock: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Add to 'blockedUsers' subcollection of current user
        try await db.collection("users").document(currentUserId).collection("blockedUsers").document(userIdToBlock).setData([
            "blockedAt": Timestamp(date: Date())
        ])
    }
    
    // MARK: - User Management (Admin)
    func searchUsers(query: String) async throws -> [User] {
        // Search by Email (for Manage Users)
        let snapshot = try await db.collection("users")
            .whereField("email", isGreaterThanOrEqualTo: query)
            .whereField("email", isLessThan: query + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()
            
        return snapshot.documents.compactMap { try? $0.data(as: User.self) }
    }
    
    func searchUsersByName(query: String) async throws -> [User] {
        // Search by DisplayName (for Ban User)
        let snapshot = try await db.collection("users")
            .whereField("displayName", isGreaterThanOrEqualTo: query)
            .whereField("displayName", isLessThan: query + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()
            
        return snapshot.documents.compactMap { try? $0.data(as: User.self) }
    }
    
    func updateUserRole(userId: String, role: UserRole) async throws {
        try await db.collection("users").document(userId).updateData([
            "role": role.rawValue
        ])
    }
    
    func sendNotification(_ notification: AppNotification) async throws {
        try db.collection("notifications").document(notification.id ?? UUID().uuidString).setData(from: notification)
    }
}
