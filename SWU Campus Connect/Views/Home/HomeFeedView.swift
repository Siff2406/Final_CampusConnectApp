import SwiftUI

struct HomeFeedView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var notificationManager = NotificationManager.shared  
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                 
                HStack {
                    Text("Campus Connect")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.swuRed)
                    
                    Spacer()
                    
                    NavigationLink(destination: NotificationsView()) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.title3)
                                .foregroundColor(.swuTextPrimary)
                            
                            if notificationManager.unreadCount > 0 {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(Color.swuBackground)
                
                 
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                         
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search events...", text: $viewModel.searchText)
                            if !viewModel.searchText.isEmpty {
                                Button(action: { viewModel.searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
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
                             
                            if viewModel.searchText.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Latest Events")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                             
                                            ForEach(viewModel.events.filter { $0.eventDate >= Date() }.sorted(by: { $0.createdAt > $1.createdAt }).prefix(3)) { event in
                                                NavigationLink(destination: EventDetailView(event: event)) {
                                                    FeaturedEventCard(event: event)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            
                             
                            VStack(alignment: .leading, spacing: 16) {
                                Text(viewModel.searchText.isEmpty ? "News Feed" : "Search Results")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                LazyVStack(spacing: 16) {
                                    ForEach(viewModel.filteredEvents) { event in
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
                    .padding(.bottom, 80)  
                }
                .refreshable {
                    viewModel.fetchEvents()
                    notificationManager.fetchNotifications()  
                }
                .padding(.bottom, 100)  
            }
            .navigationBarHidden(true)
            .background(Color.swuBackground)  
            .onAppear {
                viewModel.fetchEvents()
                notificationManager.fetchNotifications()  
            }
        }
    }
}

struct FeaturedEventCard: View {
    let event: Event
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CachedAsyncImage(url: event.imageUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
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
                    .background(Color.swuRed)  
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
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
