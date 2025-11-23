import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    private init() {}
    
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
    
    func addEvent(_ event: Event) async throws {
        try db.collection("events").document(event.id).setData(from: event)
    }
    
    func updateEventStatus(eventId: String, status: EventStatus) async throws {
        try await db.collection("events").document(eventId).updateData([
            "status": status.rawValue
        ])
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
