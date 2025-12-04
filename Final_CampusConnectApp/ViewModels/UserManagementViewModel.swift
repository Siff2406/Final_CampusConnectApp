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
        // Debounce search text
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
                // Filter out current user
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
                
                // Update local list
                if users.contains(where: { $0.id == user.id }) {
                    // Create a mutable copy of the user to update the role locally
                    // Since 'User' is a struct and 'role' is a let constant, we might need to rely on re-fetching or just assume success for UI feedback.
                    // Ideally User struct should have var for role or we create a new instance.
                    // For now, let's just re-search or show success message.
                    
                    self.successMessage = "Updated \(user.displayName)'s role to \(role.rawValue)"
                    
                    // Refresh search to show updated data
                    self.searchUsers(query: self.searchText)
                }
            } catch {
                self.errorMessage = "Failed to update role: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
}
