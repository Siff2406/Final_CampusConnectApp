import Foundation
import Combine

@MainActor
class BanUserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if !query.isEmpty {
                    self?.searchUsers(query: query)
                } else {
                    self?.users = []
                }
            }
            .store(in: &cancellables)
    }
    
    func searchUsers(query: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let results = try await FirebaseService.shared.searchUsersByName(query: query)
                let currentUserId = AuthService.shared.currentUser?.id
                self.users = results.filter { $0.id != currentUserId }
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
    
    func banUser(user: User) {
        isLoading = true
        Task {
            do {
                try await FirebaseService.shared.blockUser(userIdToBlock: user.id)
                self.successMessage = "Banned \(user.displayName)"
            } catch {
                self.errorMessage = "Failed to ban user: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
}
