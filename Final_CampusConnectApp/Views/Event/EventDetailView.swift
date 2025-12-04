import SwiftUI
import FirebaseAuth

struct EventDetailView: View {
    let event: Event
    @Environment(\.dismiss) var dismiss
    
    @State private var isJoined = false
    @State private var showJoinSheet = false
    @State private var isLoadingStatus = true
    @State private var showDeleteAlert = false // For delete confirmation
    @State private var showGuestAlert = false // For guest alert
    @State private var organizerProfile: User?
    
    // Calendar Alert States
    @State private var showCalendarAlert = false
    @State private var calendarAlertMessage = ""
    @State private var calendarAlertTitle = ""
    @State private var showTicket = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header Image
                    GeometryReader { geometry in
                        if !event.imageUrl.isEmpty && !event.imageUrl.contains("placeholder.com") {
                            CachedAsyncImage(url: event.imageUrl) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: 300)
                                    .clipped()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: geometry.size.width, height: 300)
                            }
                        } else {
                            // Default Image
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                Image(systemName: "photo.on.rectangle.angled")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100)
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            .frame(width: geometry.size.width, height: 300)
                        }
                    }
                    .frame(height: 300)
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
                                .foregroundColor(.swuRed) // Changed to swuRed
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.swuRed.opacity(0.1)) // Changed to swuRed opacity
                                .cornerRadius(8)
                            
                            Text(event.title)
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        
                        // Info Rows
                        VStack(spacing: 16) {
                            InfoRow(icon: "calendar", title: "Date & Time", subtitle: event.eventDate.formatted(date: .abbreviated, time: .shortened))
                            
                            Button(action: {
                                let query = event.location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                InfoRow(icon: "mappin.and.ellipse", title: "Location", subtitle: event.location)
                            }
                            .buttonStyle(PlainButtonStyle())
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
                                if let organizer = organizerProfile {
                                    Text(organizer.displayName)
                                        .font(.headline)
                                } else {
                                    Text("User ID: \(event.createBy.prefix(6))...")
                                        .font(.headline)
                                }
                            }
                        }
                        .onAppear {
                            fetchOrganizerProfile()
                        }

                        
                        // Padding for bottom bar
                        Color.clear.frame(height: 20)
                    }
                    .padding(24)
                    .background(Color.white)
                    .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                    .offset(y: -30)
                }
            }
            .edgesIgnoringSafeArea(.top)
            
            // 3. Bottom Action Bar (Fixed at bottom)
            VStack {
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
                        if event.eventDate < Date() {
                            // Do nothing
                        } else if AuthService.shared.isGuest {
                            showGuestAlert = true
                        } else if isJoined {
                            showTicket = true
                        } else {
                            showJoinSheet = true
                        }
                    }) {
                        Text(event.eventDate < Date() ? "Event Ended" : (isJoined ? "View Ticket" : "Join Event"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 160, height: 50)
                            .background(event.eventDate < Date() ? Color.gray : (isJoined ? Color.swuGrey : Color.swuRed))
                            .cornerRadius(16)
                            .shadow(color: (event.eventDate < Date() ? Color.gray : (isJoined ? Color.swuGrey : Color.swuRed)).opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(isLoadingStatus && !AuthService.shared.isGuest || event.eventDate < Date())
                    .alert("Sign In Required", isPresented: $showGuestAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("Please sign in with your SWU email to join events.")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .padding(.bottom, 60) // Add padding to clear floating tab bar
                .background(Color.white)
            }
        }
        .overlay(
            // 2. Fixed Back Button & Admin Buttons (Overlay on top)
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Show Delete Button only for Admin
                if AuthService.shared.currentUser?.role == .admin {
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                
                // Add to Calendar Button
                Button(action: { addToCalendar() }) {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.swuGrey.opacity(0.9)) // Changed to swuGrey
                        .clipShape(Circle())
                }
                
                // Share Button (New)
                Button(action: {
                    // Use a dummy UIView for fallback sharing context
                    let dummyView = UIView()
                    SocialShareManager.shared.shareEventToInstagramStory(event: event, view: dummyView)
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.swuGrey.opacity(0.9)) // Changed to swuGrey
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60) // Fixed padding to clear Dynamic Island
            , alignment: .top
        )
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea(.top)
        .sheet(isPresented: $showJoinSheet) {
            JoinEventView(event: event) {
                isJoined = true
            }
        }
        .sheet(isPresented: $showTicket) {
            if let user = AuthService.shared.currentUser {
                TicketView(event: event, user: user)
            } else {
                Text("Error: User not found")
            }
        }
        .alert("Delete Event", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEvent()
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .alert(calendarAlertTitle, isPresented: $showCalendarAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(calendarAlertMessage)
        }
        .onAppear {
            checkJoinStatus()
        }
    }
    
    private func checkJoinStatus() {
        if AuthService.shared.isGuest {
            isLoadingStatus = false
            return
        }
        
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
    
    private func fetchOrganizerProfile() {
        Task {
            do {
                organizerProfile = try await FirebaseService.shared.fetchUserProfile(userId: event.createBy)
            } catch {
                print("Error fetching organizer profile: \(error)")
            }
        }
    }
    
    private func deleteEvent() {
        Task {
            do {
                try await FirebaseService.shared.deleteEvent(eventId: event.id)
                dismiss()
            } catch {
                print("Error deleting event: \(error)")
            }
        }
    }
    
    private func addToCalendar() {
        CalendarManager.shared.addEventToCalendar(
            title: event.title,
            description: event.description,
            location: event.location,
            startDate: event.eventDate
        ) { result in
            switch result {
            case .success:
                calendarAlertTitle = "Success"
                calendarAlertMessage = "Event added to your calendar!"
            case .failure(let error):
                calendarAlertTitle = "Error"
                calendarAlertMessage = error.localizedDescription
            }
            showCalendarAlert = true
        }
    }
}

// ... (InfoRow struct remains same) ...

struct InfoRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.swuRed) // Changed to swuRed
                .frame(width: 40, height: 40)
                .background(Color.swuRed.opacity(0.1)) // Changed to swuRed opacity
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
