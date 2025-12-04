import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    // Use computed property to ensure we get the instance after configuration
    private var db: Firestore {
        Firestore.firestore()
    }
    private var listeners: [ListenerRegistration] = []
    
    private init() {}
    
    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Remove existing listeners
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        
        // 1. Listen to Personal Notifications
        let personalListener = db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                self?.handleSnapshot(snapshot, type: "personal")
            }
        listeners.append(personalListener)
        
        // 2. Listen to Global Notifications
        let globalListener = db.collection("notifications")
            .whereField("userId", isEqualTo: "ALL_USERS")
            .addSnapshotListener { [weak self] snapshot, error in
                self?.handleSnapshot(snapshot, type: "global")
            }
        listeners.append(globalListener)
        
        // 3. Listen to Admin Notifications (Check role first or just listen if we assume admin check is done elsewhere. 
        // For safety, let's fetch user role first or just listen if we know they are admin. 
        // To keep it simple and fast, we'll listen, but security rules should prevent access if not admin.)
        // We'll skip admin listener here for simplicity unless we're sure, to avoid permission errors.
        // Or we can fetch user profile first.
        
        Task {
            if let user = try? await FirebaseService.shared.fetchUser(userId: userId), user.role == .admin {
                await MainActor.run {
                    let adminListener = self.db.collection("notifications")
                        .whereField("userId", isEqualTo: "ADMIN")
                        .addSnapshotListener { [weak self] snapshot, error in
                            self?.handleSnapshot(snapshot, type: "admin")
                        }
                    self.listeners.append(adminListener)
                }
            }
        }
    }
    
    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // Temporary storage to merge results
    private var personalNotifs: [AppNotification] = []
    private var globalNotifs: [AppNotification] = []
    private var adminNotifs: [AppNotification] = []
    
    private func handleSnapshot(_ snapshot: QuerySnapshot?, type: String) {
        guard let documents = snapshot?.documents else { return }
        
        let newNotifs = documents.compactMap { try? $0.data(as: AppNotification.self) }
        
        switch type {
        case "personal": personalNotifs = newNotifs
        case "global": globalNotifs = newNotifs
        case "admin": adminNotifs = newNotifs
        default: break
        }
        
        mergeAndPublish()
    }
    
    private func mergeAndPublish() {
        var all = personalNotifs + globalNotifs + adminNotifs
        // Sort by date descending
        all.sort(by: { $0.createdAt > $1.createdAt })
        
        DispatchQueue.main.async {
            self.notifications = all
            self.unreadCount = all.filter { !$0.isRead }.count
        }
    }
    
    // Keep fetchNotifications for manual refresh if needed (but listeners are better)
    func fetchNotifications() {
        startListening()
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
