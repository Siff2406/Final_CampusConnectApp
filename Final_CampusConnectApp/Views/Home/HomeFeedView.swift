import SwiftUI

struct HomeFeedView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        Text("SWU Connect")
                            .font(.title2) // SWU Identity
                            .fontWeight(.black)
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        Image(systemName: "bell.badge")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        Text("Search events, news...")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let error = viewModel.errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        // Featured Events (Horizontal Scroll)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Featured Events")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.events.prefix(3)) { event in
                                        NavigationLink(destination: EventDetailView(event: event)) {
                                            FeaturedEventCard(event: event)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // News Feed (Vertical List)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("News Feed")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.events) { event in
                                    NavigationLink(destination: EventDetailView(event: event)) {
                                        EventCardView(event: event)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchEvents()
            }
        }
    }
}

struct FeaturedEventCard: View {
    let event: Event
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: event.imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .empty:
                    Color.gray.opacity(0.3)
                case .failure:
                    Color.gray.opacity(0.3)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 280, height: 180)
            .clipped()
            
            LinearGradient(gradient: Gradient(colors: [.black.opacity(0.7), .clear]), startPoint: .bottom, endPoint: .top)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.category.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            .padding()
        }
        .frame(width: 280, height: 180)
        .cornerRadius(16)
    }
}
