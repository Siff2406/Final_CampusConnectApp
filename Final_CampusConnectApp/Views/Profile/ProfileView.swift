import SwiftUI

struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if let user = authService.currentUser {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Custom Header
                            HStack {
                                Text("Profile")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.swuTextPrimary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                            
                            // 1. Profile Header Card
                            VStack(spacing: 20) {
                                ZStack {
                                    if let imageUrl = user.profileImageUrl {
                                        CachedAsyncImage(url: imageUrl) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(roleColor(for: user.role))
                                        }
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 100)
                                            .foregroundColor(roleColor(for: user.role))
                                            .background(Circle().fill(Color.white))
                                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                                    }
                                    
                                    // Edit Button Overlay
                                    Button(action: {
                                        showingImagePicker = true
                                    }) {
                                        Image(systemName: "photo.fill") // Changed to photo icon
                                            .font(.system(size: 12)) // Smaller icon
                                            .foregroundColor(.white)
                                            .padding(6) // Reduced padding (was 8)
                                            .background(Color.swuRed)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    }
                                    .offset(x: 35, y: 35)
                                }
                                
                                if viewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                
                                VStack(spacing: 5) {
                                    Text(user.displayName)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.swuTextPrimary)
                                    
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundColor(.swuTextSecondary)
                                    
                                    // Role Badge
                                    Text(user.role.rawValue.capitalized)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.swuRed.opacity(0.1))
                                        .foregroundColor(.swuRed)
                                        .clipShape(Capsule())
                                        .padding(.top, 4)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                            
                            // 2. Menu Options
                            VStack(spacing: 16) {
                                // Admin Dashboard (Only for Admin)
                                if user.role == .admin {
                                    NavigationLink(destination: AdminDashboardView()) {
                                        ProfileMenuRow(icon: "shield.checkerboard", title: "Admin Dashboard", color: .purple)
                                    }
                                }
                                
                                // My Created Events
                                NavigationLink(destination: CreatedEventsView()) {
                                    ProfileMenuRow(icon: "calendar.badge.clock", title: "My Created Events", color: .orange)
                                }
                                
                                // Settings
                                NavigationLink(destination: SettingsView()) {
                                    ProfileMenuRow(icon: "gearshape.fill", title: "Settings", color: .gray)
                                }
                                
                                // Help & Support
                                NavigationLink(destination: HelpSupportView()) {
                                    ProfileMenuRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .blue)
                                }
                            }
                            .padding(.horizontal)
                            
                            Spacer(minLength: 20)
                            
                            // 3. Sign Out Button
                            Button(action: {
                                showingSignOutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.swuRed)
                                .cornerRadius(16)
                                .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .padding(.horizontal)
                            
                            // Version Info
                            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0")")
                                .font(.caption)
                                .foregroundColor(.swuTextSecondary)
                                .padding(.bottom, 100)
                        }
                    }
                    .sheet(isPresented: $showingImagePicker) {
                        ImagePicker(image: $inputImage)
                    }
                    .onChange(of: inputImage) { _, newImage in
                        if let image = newImage {
                            viewModel.uploadProfileImage(image)
                        }
                    }
                    .alert("Success", isPresented: $viewModel.isSuccess) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("Profile picture updated successfully.")
                    }
                    .alert("Sign Out", isPresented: $showingSignOutAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Sign Out", role: .destructive) {
                            authService.signOut()
                        }
                    } message: {
                        Text("Are you sure you want to sign out?")
                    }
                } else if authService.isGuest {
                    // Guest Profile View
                    VStack(spacing: 24) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                            .padding(.top, 60)
                        
                        Text("Guest User")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Sign in to access your profile")
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            authService.signOut() // This will reset guest state and go back to Login
                        }) {
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.swuRed)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                } else if let error = authService.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Error loading profile")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry") {
                            Task {
                                await authService.fetchUser()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ProgressView()
                        .onAppear {
                            // Force fetch if stuck
                            if authService.currentUser == nil && !authService.isGuest {
                                Task {
                                    await authService.fetchUser()
                                }
                            }
                        }
                }
            }
            .navigationBarHidden(true)
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

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(10)
            
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
