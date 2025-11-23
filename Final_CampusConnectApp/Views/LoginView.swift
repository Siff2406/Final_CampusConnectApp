import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Logo
            Image(systemName: "graduationcap.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text("SWU Connect")
                    .font(.largeTitle)
                    .fontWeight(.black)
                
                Text("Campus Events & News")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if let errorMessage = authService.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Google Sign In Button
            Button(action: {
                Task {
                    await authService.signInWithGoogle()
                }
            }) {
                HStack {
                    Image(systemName: "g.circle.fill") // Placeholder for Google Logo
                        .font(.title2)
                    Text("Sign in with SWU Account")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.red)
                .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            Text("Only @g.swu.ac.th allowed")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
