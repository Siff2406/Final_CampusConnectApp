import Foundation
import Combine
import UIKit

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    
    func uploadProfileImage(_ image: UIImage) {
        guard let user = AuthService.shared.currentUser else { return }
        
        isLoading = true
        Task {
            do {
                // 1. Upload Image
                let imageUrl = try await FirebaseService.shared.uploadImage(image)
                
                // 2. Update User Profile
                var updatedUser = user
                updatedUser.profileImageUrl = imageUrl
                
                try await FirebaseService.shared.saveUser(updatedUser)
                
                // 3. Update Local State
                AuthService.shared.currentUser = updatedUser
                
                // Force fetch from server to be 100% sure
                await AuthService.shared.fetchUser()
                
                isLoading = false
                isSuccess = true // Trigger success alert
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
