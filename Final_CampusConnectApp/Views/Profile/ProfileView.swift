import SwiftUI

struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let user = authService.currentUser {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                            .background(Circle().fill(Color.white))
                            .shadow(radius: 4)
                        
                        VStack(spacing: 4) {
                            Text(user.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // Role Badge
                        Text(user.role.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(roleColor(for: user.role).opacity(0.1))
                            .foregroundColor(roleColor(for: user.role))
                            .cornerRadius(20)
                    }
                    .padding(.top, 20)
                    
                    List {
                        Section {
                            // Admin Menu
                            if user.role == .admin {
                                NavigationLink(destination: AdminDashboardView()) {
                                    Label("Admin Dashboard", systemImage: "shield.checkerboard")
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            // Post Event (Only for Verified or Admin)
                            if user.role == .verified || user.role == .admin {
                                NavigationLink(destination: AddEventView()) { // Reusing AddEventView here if needed, or just keep it in Tab
                                    Label("My Events", systemImage: "calendar")
                                }
                            }
                        } header: {
                            Text("Menu")
                        }
                        
                        Section {
                            Button(action: {
                                authService.signOut()
                            }) {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Profile")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    func roleColor(for role: UserRole) -> Color {
        switch role {
        case .admin: return .red
        case .verified: return .blue
        case .normal: return .gray
        }
    }
}
