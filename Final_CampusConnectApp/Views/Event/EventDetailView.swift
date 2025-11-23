import SwiftUI

struct EventDetailView: View {
    let event: Event
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Image
                AsyncImage(url: URL(string: event.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 250)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 250)
                            .overlay(Image(systemName: "photo").font(.largeTitle))
                    @unknown default:
                        EmptyView()
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Title and Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event.category.rawValue)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                        
                        Text(event.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    // Info Row (Date, Location)
                    HStack(spacing: 20) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray)
                            Text(event.eventDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.gray)
                            Text(event.location)
                                .font(.subheadline)
                        }
                    }
                    .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // Description
                    Text("About Event")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    Text(event.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitleDisplayMode(.inline)
    }
}
