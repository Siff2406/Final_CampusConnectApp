import SwiftUI
import FirebaseAuth

struct EventCardView: View {
    let event: Event
    @State private var isInterested = false
    @State private var interestedCount = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ... (Image Section remains same) ...
            ZStack(alignment: .topTrailing) {
                CachedAsyncImage(url: event.imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(height: 180)
                .clipped()
                
                // Category Badge
                Text(event.category.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(12)
            }
            
            // Content Section
            HStack(alignment: .top, spacing: 16) {
                // Date Badge
                VStack(spacing: 0) {
                    Text(event.eventDate.formatted(.dateTime.month()))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .textCase(.uppercase)
                    
                    Text(event.eventDate.formatted(.dateTime.day()))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .frame(width: 50)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.05))
                .cornerRadius(8)
                
                // Text Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(event.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack {
                        Text(event.faculty.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Interested Count Display
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text("\(interestedCount)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        .padding(.trailing, 4)
                        
                        Button(action: {
                            toggleInterest()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isInterested ? "heart.fill" : "heart")
                                Text("Interested")
                            }
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(isInterested ? .white : .red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isInterested ? Color.red : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                            .cornerRadius(20)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onAppear {
            checkInterestStatus()
        }
    }
    
    private func toggleInterest() {
        guard let userId = AuthService.shared.userSession?.uid else { return }
        // Optimistic update
        isInterested.toggle()
        if isInterested {
            interestedCount += 1
        } else {
            interestedCount = max(0, interestedCount - 1)
        }
        
        Task {
            do {
                let newState = try await FirebaseService.shared.toggleInterest(eventId: event.id, userId: userId)
                await MainActor.run {
                    isInterested = newState
                    // Sync count with server to be sure
                    updateInterestCount()
                }
            } catch {
                print("Error toggling interest: \(error)")
                // Revert on error
                await MainActor.run {
                    isInterested.toggle()
                    if isInterested {
                        interestedCount += 1
                    } else {
                        interestedCount = max(0, interestedCount - 1)
                    }
                }
            }
        }
    }
    
    private func checkInterestStatus() {
        guard let userId = AuthService.shared.userSession?.uid else { return }
        Task {
            do {
                isInterested = try await FirebaseService.shared.checkIfInterested(eventId: event.id, userId: userId)
                updateInterestCount()
            } catch {
                print("Error checking interest: \(error)")
            }
        }
    }
    
    private func updateInterestCount() {
        Task {
            do {
                let count = try await FirebaseService.shared.getInterestedCount(eventId: event.id)
                await MainActor.run {
                    self.interestedCount = count
                }
            } catch {
                print("Error fetching count: \(error)")
            }
        }
    }
}
