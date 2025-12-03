import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        ZStack {
            Color.swuBackground
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo Section
                VStack(spacing: 20) {
                    Image(systemName: "graduationcap.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.swuRed)
                        .padding(20)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 8) {
                        Text("Campus Connect") // Fixed typo
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.swuTextPrimary)
                        
                        Text("SWU Campus Events & News")
                            .font(.title3)
                            .foregroundColor(.swuTextSecondary)
                    }
                }
                
                Spacer()
                
                // Error Message
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.swuRed)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.swuRed.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Sign In Section
                VStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await authService.signInWithGoogle()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                            Text("Sign in with SWU Account")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.swuRed)
                        .cornerRadius(16)
                        .shadow(color: Color.swuRed.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    Text("Only @g.swu.ac.th allowed")
                        .font(.caption)
                        .foregroundColor(.swuTextSecondary)
                    
                    Button(action: {
                        authService.signInAsGuest()
                    }) {
                        Text("Continue as Guest")
                            .fontWeight(.medium)
                            .foregroundColor(.swuTextSecondary)
                            .underline()
                    }
                    .padding(.top, 8)
                    
                    // Demo Login (For Presentation)
                    HStack(spacing: 20) {
                        Button("Demo User") {
                            Task { await authService.signInAsDemoUser(role: .normal) }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        
                        Button("Demo Admin") {
                            Task { await authService.signInAsDemoUser(role: .admin) }
                        }
                        .font(.caption)
                        .foregroundColor(.purple)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .padding()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
