import SwiftUI

struct MyEventsView: View {
    @StateObject private var viewModel = MyEventsViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.events.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("You haven't posted any events yet.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.events) { event in
                    HStack(alignment: .top, spacing: 12) {
                        // Thumbnail
                        CachedAsyncImage(url: event.imageUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .clipped()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.headline)
                                .lineLimit(2)
                            
                            Text(event.eventDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // Status Badge
                            StatusBadge(status: event.status)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("My Events")
        .onAppear {
            viewModel.fetchMyEvents()
        }
    }
}

struct StatusBadge: View {
    let status: EventStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor.opacity(0.15))
            .foregroundColor(textColor)
            .cornerRadius(4)
    }
    
    var backgroundColor: Color {
        switch status {
        case .approved: return .green
        case .pending: return .orange
        case .rejected: return .red
        }
    }
    
    var textColor: Color {
        switch status {
        case .approved: return .green
        case .pending: return .orange
        case .rejected: return .red
        }
    }
}
