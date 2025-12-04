import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var showingAddEvent = false
    
    enum Tab {
        case home
        case talk
        case myEvents
        case profile
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeFeedView()
                case .talk:
                    BlogFeedView()
                case .myEvents:
                    MyEventsView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                TabBarButton(icon: "house.fill", text: "Home", isSelected: selectedTab == .home) {
                    selectedTab = .home
                }
                
                Spacer()

                TabBarButton(icon: "bubble.left.and.bubble.right.fill", text: "Talk", isSelected: selectedTab == .talk) {
                    selectedTab = .talk
                }
                
                Spacer()

                Button(action: { showingAddEvent = true }) {
                    VStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.swuRed)
                        
                        Text("Post")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.swuRed)
                    }
                }
                
                Spacer()

                TabBarButton(icon: "calendar", text: "My Events", isSelected: selectedTab == .myEvents) {
                    selectedTab = .myEvents
                }
                
                Spacer()
                
                TabBarButton(icon: "person.fill", text: "Profile", isSelected: selectedTab == .profile) {
                    selectedTab = .profile
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 10)
            .padding(.bottom, -15)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showingAddEvent) {
            AddEventView()
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .frame(height: 24)
                    .foregroundColor(isSelected ? .swuRed : .gray)
                
                Text(text)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .swuRed : .gray)
            }
            .frame(width: 60)
        }
    }
}
