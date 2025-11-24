import Foundation
import Foundation
import FirebaseFirestore

enum NotificationType: String, Codable {
    case info
    case success
    case warning
    case error
}

struct AppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String // ผู้รับแจ้งเตือน
    let title: String
    let message: String
    let type: NotificationType
    let isRead: Bool
    let createdAt: Date
}
