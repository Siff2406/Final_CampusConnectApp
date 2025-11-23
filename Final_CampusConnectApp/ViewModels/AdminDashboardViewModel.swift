import Foundation
import Combine
import SwiftUI

@MainActor
class AdminDashboardViewModel: ObservableObject {
    @Published var pendingEvents: [Event] = []
    @Published var isLoading = false
    
    func fetchPendingEvents() {
        isLoading = true
        Task {
            do {
                pendingEvents = try await FirebaseService.shared.fetchPendingEvents()
            } catch {
                print("Error fetching pending events: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    
    func updateStatus(event: Event, status: EventStatus) {
        Task {
            do {
                try await FirebaseService.shared.updateEventStatus(eventId: event.id, status: status)
                // Remove from list locally to update UI immediately
                if let index = pendingEvents.firstIndex(where: { $0.id == event.id }) {
                    pendingEvents.remove(at: index)
                }
            } catch {
                print("Error updating status: \(error.localizedDescription)")
            }
        }
    }
}
