import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(image: "graduationcap.fill", title: "Welcome to Campus Connect", description: "Your ultimate companion for university life at SWU."),
        OnboardingPage(image: "calendar.badge.clock", title: "Stay Updated", description: "Never miss an important event or activity on campus again."),
        OnboardingPage(image: "person.3.fill", title: "Join the Community", description: "Connect with friends, share updates, and be part of the SWU family.")
    ]
    
    var body: some View {
        ZStack {
            Color.swuBackground
                .ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 20) {
                            Image(systemName: pages[index].image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .foregroundColor(.swuRed)
                                .padding(.bottom, 20)
                            
                            Text(pages[index].title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.swuTextPrimary)
                                .multilineTextAlignment(.center)
                            
                            Text(pages[index].description)
                                .font(.body)
                                .foregroundColor(.swuTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        withAnimation {
                            hasSeenOnboarding = true
                        }
                    }
                }) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.swuRed)
                        .cornerRadius(16)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 50)
                }
            }
        }
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let description: String
}
