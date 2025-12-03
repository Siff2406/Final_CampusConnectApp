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
                    Text("Privacy Policy Content...")
                }
                NavigationLink("Terms of Service") {
                    Text("Terms of Service Content...")
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
                // Handle account deletion
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
    }
}
