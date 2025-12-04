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
    @Published var isGuest: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSessionListener()
    }
    
    private func setupSessionListener() {
        self.userSession = Auth.auth().currentUser
        Task {
            await fetchUser()
        }
    }
    
    func signInAsGuest() {
        isGuest = true
    }
    
    // MARK: - Demo Login (For Presentation)
    func signInAsDemoUser(role: UserRole) async {
        do {
            let result = try await Auth.auth().signInAnonymously()
            let uid = result.user.uid
            
            let count = (try? await FirebaseService.shared.getDemoUserCount(role: role)) ?? 0
            let nextNum = count + 1
            
            let demoEmail = role == .admin ? "admin@demo.swu.ac.th" : "student@demo.swu.ac.th"
            let baseName = role == .admin ? "Demo Admin" : "Demo Student"
            let displayName = "\(baseName) #\(nextNum)"
            
            let demoUser = User(
                id: uid,
                email: demoEmail,
                role: role,
                displayName: displayName,
                profileImageUrl: nil
            )

            try await FirebaseService.shared.saveUser(demoUser)
            
            self.userSession = result.user
            self.currentUser = demoUser
            self.isGuest = false
            
        } catch {
            print("Error signing in as demo user: \(error.localizedDescription)")
            self.errorMessage = "Demo login failed: \(error.localizedDescription)"
        }
    }
    
    func signInWithGoogle() async {
        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }
            
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                print("There is no root view controller!")
                return
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = result.user
            
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
            
            await createOrUpdateUser(from: authResult.user)
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.userSession = nil
            self.currentUser = nil
            self.isGuest = false
        } catch {
        }
    }
    
    func fetchUser() async {
        guard let uid = userSession?.uid else { return }
        
        do {
            if let user = try await FirebaseService.shared.fetchUser(userId: uid) {
                self.currentUser = user
            } else {
                print("User document not found for uid \(uid). Creating new profile...")
                let email = userSession?.email ?? "no-email@swu.ac.th"
                let displayName = email.components(separatedBy: "@").first ?? "User"
                
                let newUser = User(
                    id: uid,
                    email: email,
                    role: .normal,
                    displayName: displayName,
                    profileImageUrl: nil
                )
                
                try await FirebaseService.shared.saveUser(newUser)
                self.currentUser = newUser
                print("Created new profile for \(uid)")
            }
        } catch {
            print("Error fetching/creating user: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func createOrUpdateUser(from firebaseUser: FirebaseAuth.User) async {
        let user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            role: .normal,
            displayName: firebaseUser.displayName ?? "User"
        )
        
        do {
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
