import Foundation
import Combine
import SwiftUI
import PhotosUI
import FirebaseAuth

@MainActor
class AddEventViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var location: String = ""
    @Published var eventDate: Date = Date()
    @Published var faculty: EventFaculty = .science
    @Published var category: EventCategory = .academic
    
    // Image Handling
    @Published var selectedItem: PhotosPickerItem? = nil
    @Published var selectedImage: UIImage? = nil
    
    func loadSelectedImage() {
        guard let selectedItem = selectedItem else { return }
        Task {
            if let data = try? await selectedItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                self.selectedImage = uiImage
            }
        }
    }
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    
    func submitEvent() {
        guard !title.isEmpty, !description.isEmpty, !location.isEmpty else {
            errorMessage = "Please fill in all required fields."
            return
        }
        
        guard let user = AuthService.shared.userSession else {
            errorMessage = "You must be logged in."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                var finalImageUrl = "https://via.placeholder.com/400x200?text=No+Image" // Default
                
                // Upload Image if selected
                if let image = selectedImage {
                    finalImageUrl = try await FirebaseService.shared.uploadImage(image)
                }
                
                let newEvent = Event(
                    id: UUID().uuidString,
                    title: title,
                    description: description,
                    imageUrl: finalImageUrl,
                    location: location,
                    eventDate: eventDate,
                    createBy: user.uid,
                    faculty: faculty,
                    category: category,
                    status: .pending,
                    createdAt: Date()
                )
                
                try await FirebaseService.shared.addEvent(newEvent)
                isSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
