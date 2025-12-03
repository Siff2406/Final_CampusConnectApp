import SwiftUI

struct MyEventsView: View {
    @StateObject private var viewModel = MyEventsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground) // Light gray background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.events.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "ticket")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No events yet")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Events you join or create will appear here.")
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        // Custom Header
                        HStack {
                            Text("My Events")
                                .font(.system(size: 28, weight: .bold)) // Reduced from 34
                                .foregroundColor(.swuTextPrimary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10) // Closer to Dynamic Island
                        
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.events) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    MyEventCard(event: event)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                        .padding(.bottom, 80) // Clear tab bar
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchMyEvents()
            }
        }
    }
}

struct MyEventCard: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            CachedAsyncImage(url: event.imageUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(height: 150)
            .clipped()
            .overlay(
                // Status Badge Overlay
                Text(event.status.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.swuRed) // Use theme color for all statuses
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(8)
                , alignment: .topTrailing
            )
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.swuTextPrimary)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.swuRed)
                    Text(event.eventDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.swuTextSecondary)
                }
                
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.swuRed)
                    Text(event.location)
                        .font(.caption)
                        .foregroundColor(.swuTextSecondary)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading) // Force fill width
            .background(Color.white)
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
