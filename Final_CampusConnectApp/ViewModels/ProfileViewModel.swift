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

                let imageUrl = try await FirebaseService.shared.uploadImage(image)
                
                var updatedUser = user
                updatedUser.profileImageUrl = imageUrl
                
                try await FirebaseService.shared.saveUser(updatedUser)
                
                AuthService.shared.currentUser = updatedUser
                
                await AuthService.shared.fetchUser()
                
                isLoading = false
                isSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
