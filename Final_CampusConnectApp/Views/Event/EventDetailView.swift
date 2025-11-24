import SwiftUI
import FirebaseAuth

struct EventDetailView: View {
    let event: Event
    @Environment(\.dismiss) var dismiss
    
    @State private var isJoined = false
    @State private var showJoinSheet = false
    @State private var isLoadingStatus = true
    
    var body: some View {
        ZStack(alignment: .topLeading) { // Change alignment to topLeading
            // 1. Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header Image
                    CachedAsyncImage(url: event.imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 300)
                    }
                    .frame(height: 300)
                    .clipped()
                    .overlay(
                        LinearGradient(gradient: Gradient(colors: [.black.opacity(0.6), .clear]), startPoint: .top, endPoint: .bottom)
                    )
                    
                    // ... Content Container ...
                    VStack(alignment: .leading, spacing: 24) {
                        // Title & Tag
                        VStack(alignment: .leading, spacing: 8) {
                            Text(event.category.rawValue)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            
                            Text(event.title)
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        
                        // Info Rows
                        VStack(spacing: 16) {
                            InfoRow(icon: "calendar", title: "Date & Time", subtitle: event.eventDate.formatted(date: .abbreviated, time: .shortened))
                            InfoRow(icon: "mappin.and.ellipse", title: "Location", subtitle: event.location)
                        }
                        
                        Divider()
                        
                        // Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About Event")
                                .font(.headline)
                            Text(event.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        
                        Divider()
                        
                        // Organizer (Simple)
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                            
                            VStack(alignment: .leading) {
                                Text("Organized by")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("User ID: \(event.createBy.prefix(6))...")
                                    .font(.headline)
                            }
                        }
                        
                        // Padding for bottom bar
                        Color.clear.frame(height: 80)
                    }
                    .padding(24)
                    .background(Color.white)
                    .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                    .offset(y: -30)
                }
            }
            .edgesIgnoringSafeArea(.top)
            
            // 2. Fixed Back Button
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding(.leading, 20)
            // Removed top padding to align with safe area
            
            // 3. Bottom Action Bar (Fixed at bottom)
            VStack {
                Spacer()
                Divider()
                HStack {
                    VStack(alignment: .leading) {
                        Text("Price")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Free")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if !isJoined {
                            showJoinSheet = true
                        }
                    }) {
                        Text(isJoined ? "Joined" : "Join Event")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 160, height: 50)
                            .background(isJoined ? Color.green : Color.blue)
                            .cornerRadius(16)
                            .shadow(color: (isJoined ? Color.green : Color.blue).opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(isJoined || isLoadingStatus)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.white)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showJoinSheet) {
            JoinEventView(event: event) {
                isJoined = true
            }
        }
        .onAppear {
            checkJoinStatus()
        }
    }
    
    private func checkJoinStatus() {
        guard let userId = AuthService.shared.userSession?.uid else { return }
        Task {
            do {
                isJoined = try await FirebaseService.shared.checkIfJoined(eventId: event.id, userId: userId)
            } catch {
                print("Error checking join status: \(error)")
            }
            isLoadingStatus = false
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(subtitle)
                    .fontWeight(.semibold)
            }
            Spacer()
        }
    }
}

// Extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
