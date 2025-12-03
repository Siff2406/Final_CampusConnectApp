import Foundation
import Combine
import FirebaseAuth

@MainActor
class MyEventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    
    func fetchMyEvents() {
        guard let userId = AuthService.shared.userSession?.uid else { return }
        
        isLoading = true
        Task {
            do {
                events = try await FirebaseService.shared.fetchJoinedEvents(userId: userId)
            } catch {
                print("Error fetching my events: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}
