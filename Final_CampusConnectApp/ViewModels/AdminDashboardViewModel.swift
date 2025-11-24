import Foundation
import Combine
import SwiftUI

@MainActor
class AdminDashboardViewModel: ObservableObject {
    @Published var pendingEvents: [Event] = []
    @Published var approvedEventsCount: Int = 0
    @Published var eventsTodayCount: Int = 0
    @Published var isLoading = false
    
    func fetchPendingEvents() {
        isLoading = true
        Task {
            do {
                let pending = try await FirebaseService.shared.fetchPendingEvents()
                let approved = try await FirebaseService.shared.fetchApprovedEvents()
                
                await MainActor.run {
                    self.pendingEvents = pending
                    self.approvedEventsCount = approved.count
                    
                    // Calculate events today
                    let calendar = Calendar.current
                    self.eventsTodayCount = approved.filter { calendar.isDateInToday($0.eventDate) }.count
                    
                    self.isLoading = false
                }
            } catch {
                print("Error fetching admin data: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }
    
    func updateStatus(event: Event, status: EventStatus) {
        Task {
            do {
                // 1. Update Event Status
                try await FirebaseService.shared.updateEventStatus(eventId: event.id, status: status)
                
                // 2. Send Notification to User
                let message = status == .approved 
                    ? "Your event '\(event.title)' has been approved and is now live!" 
                    : "Your event '\(event.title)' has been rejected."
                
                let type: NotificationType = status == .approved ? .success : .error
                
                let notification = AppNotification(
                    userId: event.createBy,
                    title: "Event Status Update",
                    message: message,
                    type: type,
                    isRead: false,
                    createdAt: Date()
                )
                
                try await FirebaseService.shared.addNotification(notification)
                
                // 3. Refresh UI
                fetchPendingEvents()
            } catch {
                print("Error updating status: \(error.localizedDescription)")
            }
        }
    }
}
