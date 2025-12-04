import SwiftUI
import FirebaseAuth

struct JoinEventView: View {
    let event: Event
    @Environment(\.dismiss) var dismiss
    
    @State private var fullName = ""
    @State private var studentId = ""
    @State private var faculty = ""
    @State private var phoneNumber = ""
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var onSuccess: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    Text(event.title)
                        .font(.headline)
                    Text(event.eventDate.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Your Information")) {
                    TextField("Full Name", text: $fullName)
                    TextField("Student ID", text: $studentId)
                        .keyboardType(.numberPad)
                    TextField("Faculty", text: $faculty)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: submitJoinRequest) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Confirm Join")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Join Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitJoinRequest() {
        guard !fullName.isEmpty, !studentId.isEmpty, !faculty.isEmpty else {
            errorMessage = "Please fill in all required fields."
            return
        }
        
        guard let userId = AuthService.shared.userSession?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        let details: [String: Any] = [
            "fullName": fullName,
            "studentId": studentId,
            "faculty": faculty,
            "phoneNumber": phoneNumber
        ]
        
        Task {
            do {
                try await FirebaseService.shared.joinEvent(eventId: event.id, userId: userId, details: details)
                await MainActor.run {
                    isLoading = false
                    onSuccess()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
