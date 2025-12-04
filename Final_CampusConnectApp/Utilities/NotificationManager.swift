import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private init() {}
    
    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Listen to User's Notifications
        _ = db.collection("notifications")
            .whereField("userId", in: [userId, "ALL_USERS", "ADMIN"]) // Note: 'in' query limitation
        
        // Simplified: Listen to specific user ID first (most common)
        // For complex queries (OR logic), we might need separate listeners or client-side filtering.
        // Let's stick to simple fetching for now but make it accessible globally.
        
        fetchNotifications()
    }
    
    func fetchNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task { @MainActor in
            do {
                // 1. Fetch personal
                var all = try await FirebaseService.shared.fetchNotifications(userId: userId)
                
                // 2. Fetch Global
                let global = try await FirebaseService.shared.fetchNotifications(userId: "ALL_USERS")
                all.append(contentsOf: global)
                
                // 3. Fetch Admin (if applicable)
                if let user = try? await FirebaseService.shared.fetchUser(userId: userId), user.role == .admin {
                    let adminNotifs = try await FirebaseService.shared.fetchNotifications(userId: "ADMIN")
                    all.append(contentsOf: adminNotifs)
                }
                
                // Sort and Update
                self.notifications = all.sorted(by: { $0.createdAt > $1.createdAt })
                self.unreadCount = self.notifications.filter { !$0.isRead }.count
                
            } catch {
                print("Error fetching notifications: \(error)")
            }
        }
    }
    
    func markAsRead(_ notification: AppNotification) {
        guard let id = notification.id else { return }
        
        // Optimistic Update
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = true
            unreadCount = notifications.filter { !$0.isRead }.count
        }
        
        Task {
            try? await FirebaseService.shared.markNotificationAsRead(notificationId: id)
        }
    }
    
    func markAllAsRead() {
        // Optimistic
        for i in 0..<notifications.count {
            notifications[i].isRead = true
        }
        unreadCount = 0
        
        // Server update (batch)
        Task {
            for notification in notifications where notification.id != nil {
                try? await FirebaseService.shared.markNotificationAsRead(notificationId: notification.id!)
            }
        }
    }
}
