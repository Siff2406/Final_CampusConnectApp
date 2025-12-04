import SwiftUI

struct SendAnnouncementView: View {
    @State private var title = ""
    @State private var message = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Announcement Details")) {
                TextField("Title", text: $title)
                TextEditor(text: $message)
                    .frame(height: 100)
            }
            
            Section {
                Button(action: sendAnnouncement) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Send to All Users")
                            .foregroundColor(.red)
                    }
                }
                .disabled(title.isEmpty || message.isEmpty || isLoading)
            }
        }
        .navigationTitle("Send Announcement")
        .alert(isPresented: $showSuccess) {
            Alert(
                title: Text("Success"),
                message: Text("Announcement sent successfully."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func sendAnnouncement() {
        isLoading = true
        Task {
            do {
                // In a real app, this should be done via Cloud Functions to avoid client-side iteration
                // For this demo, we'll just create a notification for "ALL" (simulated)
                // Or we can just add to a global notifications collection if we had one.
                // But to make it work with current system, let's just create one generic notification
                // that the app fetches.
                
                // NOTE: Since we don't have Cloud Functions, we'll simulate by sending to "ALL_USERS"
                // and update NotificationsViewModel to fetch from there too.
                
                let notification = AppNotification(
                    id: UUID().uuidString,
                    userId: "ALL_USERS",
                    title: title,
                    message: message,
                    type: .info,
                    isRead: false,
                    createdAt: Date()
                )
                
                try await FirebaseService.shared.sendNotification(notification)
                
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
