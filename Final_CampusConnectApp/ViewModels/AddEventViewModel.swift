import Foundation
import Combine
import SwiftUI

@MainActor
class AddEventViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var location: String = ""
    @Published var imageUrl: String = ""
    @Published var eventDate: Date = Date()
    @Published var faculty: EventFaculty = .science
    @Published var category: EventCategory = .academic
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    
    func submitEvent() {
        guard !title.isEmpty, !description.isEmpty, !location.isEmpty else {
            errorMessage = "Please fill in all required fields."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let newEvent = Event(
            id: UUID().uuidString,
            title: title,
            description: description,
            imageUrl: imageUrl.isEmpty ? "https://via.placeholder.com/300" : imageUrl,
            location: location,
            eventDate: eventDate,
            createBy: "current_user_id", // Placeholder for Auth
            faculty: faculty,
            category: category,
            status: .pending,
            createdAt: Date()
        )
        
        Task {
            do {
                try await FirebaseService.shared.addEvent(newEvent)
                isSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
