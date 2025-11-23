import SwiftUI

struct MainTabView: View {
    @State private var showingAddEvent = false
    
    var body: some View {
        TabView {
            HomeFeedView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            // This is a bit of a hack to have a button-like tab
            Text("Post Event")
                .onAppear { showingAddEvent = true }
                .tabItem {
                    Label("Post", systemImage: "plus.circle.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .accentColor(.red)
        .sheet(isPresented: $showingAddEvent) {
            AddEventView()
        }
    }
}
