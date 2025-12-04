import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    var body: some View {
        Group {
            if authService.userSession != nil || authService.isGuest {
                MainTabView()
            } else {
                if hasSeenOnboarding {
                    LoginView()
                } else {
                    OnboardingView()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
