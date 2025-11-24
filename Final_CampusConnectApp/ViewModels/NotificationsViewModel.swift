import Foundation
import Combine
import FirebaseAuth

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    
    func fetchNotifications() {
        guard let userId = AuthService.shared.userSession?.uid else { return }
        
        isLoading = true
        Task {
            do {
                notifications = try await FirebaseService.shared.fetchNotifications(userId: userId)
            } catch {
                print("Error fetching notifications: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}
