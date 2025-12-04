import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var emailNotifications = true
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Notifications")) {
                Toggle("Push Notifications", isOn: $notificationsEnabled)
                    .tint(.swuRed)
                Toggle("Email Updates", isOn: $emailNotifications)
                    .tint(.swuRed)
            }
            
            Section(header: Text("Account")) {
                NavigationLink("Privacy Policy") {
                    ScrollView {
                        Text("Privacy Policy\n\nThis application collects user data such as email and profile information solely for the purpose of authentication and event management. We do not share your data with third parties.")
                            .padding()
                    }
                    .navigationTitle("Privacy Policy")
                }
                NavigationLink("Terms of Service") {
                    ScrollView {
                        Text("Terms of Service\n\nBy using Campus Connect, you agree to behave respectfully towards other members of the SWU community. Inappropriate content may be removed and users may be banned.")
                            .padding()
                    }
                    .navigationTitle("Terms of Service")
                }
            }
            
            Section {
                Button(role: .destructive, action: {
                    showingDeleteAlert = true
                }) {
                    Text("Delete Account")
                        .foregroundColor(.swuRed)
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Delete Account", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                 
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
    }
}
