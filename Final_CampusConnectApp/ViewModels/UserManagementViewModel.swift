import Foundation
import Combine

@MainActor
class UserManagementViewModel: ObservableObject {
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
                let results = try await FirebaseService.shared.searchUsers(query: query)
                let currentUserId = AuthService.shared.currentUser?.id
                self.users = results.filter { $0.id != currentUserId }
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
    
    func promoteToAdmin(user: User) {
        updateRole(user: user, role: .admin)
    }
    
    func demoteToNormal(user: User) {
        updateRole(user: user, role: .normal)
    }
    
    private func updateRole(user: User, role: UserRole) {
        isLoading = true
        Task {
            do {
                try await FirebaseService.shared.updateUserRole(userId: user.id, role: role)

                if users.contains(where: { $0.id == user.id }) {

                    self.successMessage = "Updated \(user.displayName)'s role to \(role.rawValue)"

                    self.searchUsers(query: self.searchText)
                }
            } catch {
                self.errorMessage = "Failed to update role: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
}
