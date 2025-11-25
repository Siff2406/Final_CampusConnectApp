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
    @Published var date: Date = Date()
    @Published var faculty: EventFaculty = .science // Added back
    @Published var category: EventCategory = .academic
    @Published var imageUrlString = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    
    func createEvent() {
        guard let userId = AuthService.shared.userSession?.uid else {
            errorMessage = "Please login first"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Use provided URL or a default placeholder if empty
                let finalImageUrl = imageUrlString.isEmpty ? "https://via.placeholder.com/300" : imageUrlString
                
                let event = Event(
                    id: UUID().uuidString,
                    title: title,
                    description: description,
                    imageUrl: finalImageUrl, // Pass String directly
                    location: location,
                    eventDate: date,
                    createBy: userId,
                    faculty: faculty, // Added back
                    category: category,
                    status: .pending,
                    createdAt: Date()
                )
                
                try await FirebaseService.shared.addEvent(event)
                
                await MainActor.run {
                    isLoading = false
                    isSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
