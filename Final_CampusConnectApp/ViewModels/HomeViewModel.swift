import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchEvents() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                events = try await FirebaseService.shared.fetchApprovedEvents()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
