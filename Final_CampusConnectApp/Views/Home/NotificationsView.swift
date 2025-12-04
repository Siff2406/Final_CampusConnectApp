import SwiftUI

struct NotificationsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var selectedEvent: Event?
    @State private var selectedPost: BlogPost?
    
    var body: some View {
        ScrollView {
            if notificationManager.notifications.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.largeTitle)
                        .foregroundColor(.swuTextSecondary)
                    Text("No notifications yet")
                        .foregroundColor(.swuTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    let today = notificationManager.notifications.filter { Calendar.current.isDateInToday($0.createdAt) }
                    let earlier = notificationManager.notifications.filter { !Calendar.current.isDateInToday($0.createdAt) }
                    
                    if !today.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Today")
                                .font(.headline)
                                .foregroundColor(.swuTextSecondary)
                            
                            ForEach(today) { notification in
                                NotificationRow(notification: notification)
                                    .onTapGesture {
                                        handleNotificationTap(notification)
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if !earlier.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Earlier")
                                .font(.headline)
                                .foregroundColor(.swuTextSecondary)
                            
                            ForEach(earlier) { notification in
                                NotificationRow(notification: notification)
                                    .onTapGesture {
                                        handleNotificationTap(notification)
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Notifications")
        .refreshable {
            notificationManager.fetchNotifications() // This calls startListening which refreshes listeners
        }
        .onAppear {
            notificationManager.startListening()
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
        }
        .sheet(item: $selectedPost) { post in
            CommentsView(post: post)
        }
    }
    
    private func handleNotificationTap(_ notification: AppNotification) {
        // Mark as read
        notificationManager.markAsRead(notification)
        
        if let type = notification.relatedItemType, let id = notification.relatedItemId {
            Task {
                if type == "event" {
                    if let event = try? await FirebaseService.shared.fetchEvent(id: id) {
                        selectedEvent = event
                    }
                } else if type == "post" {
                    if let post = try? await FirebaseService.shared.fetchPost(id: id) {
                        selectedPost = post
                    }
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Circle()
                .fill(iconColor.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: iconName)
                        .foregroundColor(iconColor)
                        .font(.title3)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(notification.isRead ? .regular : .semibold)
                    .foregroundColor(.swuTextPrimary)
                    .lineLimit(2)
                
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.swuTextSecondary)
                    .lineLimit(2)
                
                Text(timeAgo(from: notification.createdAt))
                    .font(.caption2)
                    .foregroundColor(.swuTextSecondary)
            }
            
            Spacer()
            
            // Unread Dot
            if !notification.isRead {
                Circle()
                    .fill(Color.swuRed)
                    .frame(width: 8, height: 8)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private var iconName: String {
        switch notification.type {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .success: return .green
        case .error: return .swuRed
        case .warning: return .orange
        case .info: return .blue
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
