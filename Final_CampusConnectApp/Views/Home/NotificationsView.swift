import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if viewModel.notifications.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.largeTitle)
                        .foregroundColor(.swuTextSecondary) // Changed to swuTextSecondary
                    Text("No notifications yet")
                        .foregroundColor(.swuTextSecondary) // Changed to swuTextSecondary
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    // Group notifications by date (Today vs Earlier)
                    let today = viewModel.notifications.filter { Calendar.current.isDateInToday($0.createdAt) }
                    let earlier = viewModel.notifications.filter { !Calendar.current.isDateInToday($0.createdAt) }
                    
                    if !today.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Today")
                                .font(.headline)
                                .foregroundColor(.swuTextSecondary) // Changed to swuTextSecondary
                                .padding(.horizontal)
                            
                            ForEach(today) { notification in
                                NotificationRow(notification: notification)
                            }
                        }
                    }
                    
                    if !earlier.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Earlier")
                                .font(.headline)
                                .foregroundColor(.swuTextSecondary) // Changed to swuTextSecondary
                                .padding(.horizontal)
                            
                            ForEach(earlier) { notification in
                                NotificationRow(notification: notification)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.fetchNotifications()
        }
        .refreshable {
            viewModel.fetchNotifications()
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
                    .foregroundColor(.swuTextPrimary) // Changed to swuTextPrimary
                    .lineLimit(2)
                
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.swuTextSecondary) // Changed to swuTextSecondary
                    .lineLimit(2)
                
                Text(timeAgo(from: notification.createdAt))
                    .font(.caption2)
                    .foregroundColor(.swuTextSecondary) // Changed to swuTextSecondary
            }
            
            Spacer()
            
            // Unread Dot
            if !notification.isRead {
                Circle()
                    .fill(Color.swuRed) // Changed to swuRed
                    .frame(width: 8, height: 8)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    var iconName: String {
        switch notification.type {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch notification.type {
        case .success: return .green
        case .error: return .swuRed // Changed to swuRed
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
