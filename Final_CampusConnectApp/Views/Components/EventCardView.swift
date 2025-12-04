import SwiftUI
import FirebaseAuth

struct EventCardView: View {
    let event: Event
    @State private var isInterested = false
    @State private var interestedCount: Int
    
    init(event: Event) {
        self.event = event
        _interestedCount = State(initialValue: event.interestedCount)
    }
    
    var isEnded: Bool {
        event.eventDate < Date()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
             
            ZStack(alignment: .topTrailing) {
                Group {
                    if !event.imageUrl.isEmpty && !event.imageUrl.contains("placeholder.com") {
                        CachedAsyncImage(url: event.imageUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                    } else {
                         
                        Image(systemName: "photo.on.rectangle.angled")  
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(40)
                            .foregroundColor(.gray.opacity(0.5))
                            .background(Color.gray.opacity(0.1))
                    }
                }
                .frame(height: 180)
                .clipped()
                
                 
                Text(event.category.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isEnded ? Color.gray : Color.swuRed)  
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(12)
                
                if isEnded {
                    Color.black.opacity(0.4)  
                    
                    Text("ENDED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(4)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .topLeading)  
                }
            }
            
             
            HStack(alignment: .top, spacing: 16) {
                 
                VStack(spacing: 0) {
                    Text(event.eventDate.formatted(.dateTime.month()))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.swuRed)  
                        .textCase(.uppercase)
                    
                    Text(event.eventDate.formatted(.dateTime.day()))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.swuTextPrimary)  
                }
                .frame(width: 50)
                .padding(.vertical, 8)
                .background(Color.swuRed.opacity(0.05))  
                .cornerRadius(8)
                
                 
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.swuTextPrimary)  
                    
                    Text(event.location)
                        .font(.caption)
                        .foregroundColor(.swuTextSecondary)  
                        .lineLimit(1)
                    
                    HStack {
                        Text(event.faculty.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.swuGrey.opacity(0.1))  
                            .cornerRadius(4)
                            .foregroundColor(.swuTextSecondary)  
                        
                        Spacer()
                        
                         
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundColor(.swuRed)  
                            Text("\(interestedCount)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.swuTextSecondary)  
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
                            .foregroundColor(isInterested ? .white : .swuRed)  
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isInterested ? Color.swuRed : Color.white)  
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.swuRed, lineWidth: 1)  
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
        .saturation(isEnded ? 0 : 1)  
        .onAppear {
            checkInterestStatus()
        }
    }
    
    private func toggleInterest() {
        guard let userId = AuthService.shared.userSession?.uid else { return }
         
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
                     
                    updateInterestCount()
                }
            } catch {
                print("Error toggling interest: \(error)")
                 
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
