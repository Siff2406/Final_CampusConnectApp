import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    
    var hasUnread: Bool {
        notifications.contains { !$0.isRead }
    }
    
    func fetchNotifications() {
        guard let userId = AuthService.shared.userSession?.uid else { return }
        
        isLoading = true
        Task {
            do {
                var allNotifications = try await FirebaseService.shared.fetchNotifications(userId: userId)
                
                if AuthService.shared.currentUser?.role == .admin {
                    let adminNotifications = try await FirebaseService.shared.fetchNotifications(userId: "ADMIN")
                    allNotifications.append(contentsOf: adminNotifications)
                }

                let globalNotifications = try await FirebaseService.shared.fetchNotifications(userId: "ALL_USERS")
                allNotifications.append(contentsOf: globalNotifications)
                notifications = allNotifications.sorted(by: { $0.createdAt > $1.createdAt })
                
            } catch {
                print("Error fetching notifications: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    
    func fetchEvent(id: String) async throws -> Event? {
        let doc = try await Firestore.firestore().collection("events").document(id).getDocument()
        return try? doc.data(as: Event.self)
    }
    
    func fetchPost(id: String) async throws -> BlogPost? {
        let doc = try await Firestore.firestore().collection("posts").document(id).getDocument()
        return try? doc.data(as: BlogPost.self)
    }
}
