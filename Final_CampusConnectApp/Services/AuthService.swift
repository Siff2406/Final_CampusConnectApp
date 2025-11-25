import Foundation
import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var errorMessage: String?
    
    private init() {
        self.userSession = Auth.auth().currentUser
        Task {
            await fetchUser()
        }
    }
    
    func signInWithGoogle() async {
        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }
            
            // Create Google Sign In configuration object.
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            // Start the sign in flow!
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                print("There is no root view controller!")
                return
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = result.user
            
            // Check domain
            guard let email = user.profile?.email, email.hasSuffix("@g.swu.ac.th") else {
                errorMessage = "กรุณาใช้อีเมล @g.swu.ac.th เท่านั้น"
                GIDSignIn.sharedInstance.signOut()
                return
            }
            
            guard let idToken = user.idToken?.tokenString else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            self.userSession = authResult.user
            
            // Create or Update User in Firestore
            await createOrUpdateUser(from: authResult.user)
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut() // Ensure Google Sign In is also signed out
            self.userSession = nil
            self.currentUser = nil
        } catch {
            print("DEBUG: Error signing out \(error.localizedDescription)")
        }
    }
    
    private func fetchUser() async {
        guard let uid = userSession?.uid else { return }
        
        do {
            self.currentUser = try await FirebaseService.shared.fetchUser(userId: uid)
        } catch {
            print("DEBUG: Failed to fetch user \(error.localizedDescription)")
        }
    }
    
    private func createOrUpdateUser(from firebaseUser: FirebaseAuth.User) async {
        let user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            role: .normal, // Default role
            displayName: firebaseUser.displayName ?? "User"
        )
        
        do {
            // Check if user exists first to avoid overwriting role
            if let existingUser = try await FirebaseService.shared.fetchUser(userId: user.id) {
                self.currentUser = existingUser
            } else {
                try await FirebaseService.shared.saveUser(user)
                self.currentUser = user
            }
        } catch {
            print("DEBUG: Failed to save user \(error.localizedDescription)")
        }
    }
}
