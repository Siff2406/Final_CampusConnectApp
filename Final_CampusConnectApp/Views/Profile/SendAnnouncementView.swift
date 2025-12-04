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
