import SwiftUI
import Combine
import FirebaseAuth
import Foundation

struct CreatedEventsView: View {
    @StateObject private var viewModel = CreatedEventsViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.swuBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.swuTextPrimary)
                    }
                    
                    Text("Created Events")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.swuTextPrimary)
                        .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding()
                .background(Color.white)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.events.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("You haven't created any events yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.events) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventCardView(event: event)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.fetchCreatedEvents()
        }
    }
}

class CreatedEventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    
    @MainActor
    func fetchCreatedEvents() {
        guard let userId = AuthService.shared.userSession?.uid else { return }
        
        isLoading = true
        Task {
            do {
                events = try await FirebaseService.shared.fetchUserEvents(userId: userId)
            } catch {
                print("Error fetching created events: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}
