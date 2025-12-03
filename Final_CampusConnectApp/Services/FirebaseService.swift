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
    
    func fetchJoinedEvents(userId: String) async throws -> [Event] {
        // 1. Find all participant documents for this user across all events
        // Note: This requires a Collection Group Index on 'participants' collection for field 'userId'
        let snapshot = try await db.collectionGroup("participants")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        var events: [Event] = []
        
        // 2. Get the parent Event document for each participation
        for doc in snapshot.documents {
            // The parent of 'participants' collection is the 'events' document
            if let eventRef = doc.reference.parent.parent {
                let eventDoc = try await eventRef.getDocument()
                if let event = try? eventDoc.data(as: Event.self) {
                    events.append(event)
                }
            }
        }
        
        // Sort by date (newest first)
        return events.sorted(by: { $0.eventDate > $1.eventDate })
    }
    
    func addEvent(_ event: Event) async throws {
        try db.collection("events").document(event.id).setData(from: event)
    }
    
    func uploadImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let filename = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("event_images/\(filename)")
        
        let _ = try await storageRef.putDataAsync(imageData)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
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
        // Add to 'participants' subcollection
        try await db.collection("events").document(eventId).collection("participants").document(userId).setData(data)
    }
    
    func checkIfJoined(eventId: String, userId: String) async throws -> Bool {
        let doc = try await db.collection("events").document(eventId).collection("participants").document(userId).getDocument()
        return doc.exists
    }
    
    func toggleInterest(eventId: String, userId: String) async throws -> Bool {
        let docRef = db.collection("events").document(eventId).collection("interested").document(userId)
        let doc = try await docRef.getDocument()
        
        if doc.exists {
            try await docRef.delete()
            return false // No longer interested
        } else {
            try await docRef.setData(["interestedAt": Timestamp(date: Date())])
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
}
