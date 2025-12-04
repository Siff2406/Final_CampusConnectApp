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

        listeners.forEach { $0.remove() }
        listeners.removeAll()
        
        let personalListener = db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                self?.handleSnapshot(snapshot, type: "personal")
            }
        listeners.append(personalListener)

        let globalListener = db.collection("notifications")
            .whereField("userId", isEqualTo: "ALL_USERS")
            .addSnapshotListener { [weak self] snapshot, error in
                self?.handleSnapshot(snapshot, type: "global")
            }
        listeners.append(globalListener)
        
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
    
    func fetchNotifications() {
        startListening()
    }
    
    func markAsRead(_ notification: AppNotification) {
        guard let id = notification.id else { return }
        
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
        
        Task {
            for notification in notifications where notification.id != nil {
                try? await FirebaseService.shared.markNotificationAsRead(notificationId: notification.id!)
            }
        }
    }
}
