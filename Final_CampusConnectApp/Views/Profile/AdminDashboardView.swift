import SwiftUI

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminDashboardViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. Stats Row
                HStack(spacing: 12) {
                    StatCard(title: "Events Today", value: "\(viewModel.eventsTodayCount)", color: .blue)
                    StatCard(title: "Active Posts", value: "\(viewModel.approvedEventsCount)", color: .green)
                    StatCard(title: "Pending", value: "\(viewModel.pendingEvents.count)", color: .orange)
                }
                .padding(.horizontal)
                
                // 2. Pending Posts Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Pending Posts")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if viewModel.pendingEvents.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.largeTitle)
                                .foregroundColor(.green)
                            Text("All Caught Up!")
                                .font(.headline)
                            Text("The pending posts queue is empty.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        ForEach(viewModel.pendingEvents) { event in
                            PendingEventCard(event: event, onApprove: {
                                viewModel.updateStatus(event: event, status: .approved)
                            }, onReject: {
                                viewModel.updateStatus(event: event, status: .rejected)
                            })
                            .padding(.horizontal)
                        }
                    }
                }
                
                // 3. Admin Tools
                VStack(alignment: .leading, spacing: 16) {
                    Text("Admin Tools")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        NavigationLink(destination: UserManagementView()) {
                            AdminToolButton(title: "Manage Users", icon: "person.2.badge.gearshape.fill", color: .blue)
                        }
                        
                        NavigationLink(destination: BanUserView()) {
                            AdminToolButton(title: "Ban a User", icon: "slash.circle", color: .orange)
                        }
                        
                        NavigationLink(destination: ManagePostsView()) {
                            AdminToolButton(title: "Hide a Post", icon: "eye.slash", color: .gray)
                        }
                        
                        NavigationLink(destination: SendAnnouncementView()) {
                            AdminToolButton(title: "Send Announcement", icon: "megaphone", color: .red)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .padding(.bottom, 100) // Avoid TabBar overlap
        }
        .navigationTitle("Moderator Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.fetchPendingEvents()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.swuTextSecondary) // Changed to swuTextSecondary
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct PendingEventCard: View {
    let event: Event
    let onApprove: () -> Void
    let onReject: () -> Void
    @State private var userProfile: User?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: User & Time
            HStack {
                if let profileUrl = userProfile?.profileImageUrl {
                    CachedAsyncImage(url: profileUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                    }
                } else {
                    Circle()
                        .fill(Color.swuGrey.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(Image(systemName: "person.fill").foregroundColor(.swuGrey))
                }
                
                VStack(alignment: .leading) {
                    Text(userProfile?.displayName ?? "User ID: \(event.createBy.prefix(6))...")
                        .fontWeight(.semibold)
                    Text(timeAgo(from: event.createdAt))
                        .font(.caption)
                        .foregroundColor(.swuTextSecondary)
                }
                Spacer()
                Text(event.category.rawValue)
                    .font(.caption2)
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .onAppear {
                Task {
                    userProfile = try? await FirebaseService.shared.fetchUserProfile(userId: event.createBy)
                }
            }
            
            Divider()
            
            // Event Content
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
                        .foregroundColor(.swuRed) // Changed to swuRed
                    
                    Text(event.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(event.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onReject) {
                    Text("Reject")
                        .fontWeight(.semibold)
                        .foregroundColor(.swuRed) // Changed to swuRed
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.swuRed.opacity(0.1)) // Changed to swuRed
                        .cornerRadius(8)
                }
                
                Button(action: onApprove) {
                    Text("Approve")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct AdminToolButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
            Spacer()
        }
        .foregroundColor(.white)
        .padding()
        .background(color)
        .cornerRadius(12)
    }
}
