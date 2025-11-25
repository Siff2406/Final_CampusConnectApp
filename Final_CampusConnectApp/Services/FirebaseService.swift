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
            print("DEBUG: Firestore cache cleared successfully")
        } catch {
            print("DEBUG: Failed to clear Firestore cache: \(error)")
        }
    }
    
    // MARK: - Events
    
    func fetchApprovedEvents() async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("status", isEqualTo: EventStatus.approved.rawValue)
            .order(by: "eventDate", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Event.self)
        }
    }
    
    func fetchPendingEvents() async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("status", isEqualTo: EventStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
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
}
