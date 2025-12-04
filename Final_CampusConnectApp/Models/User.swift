import Foundation

enum UserRole: String, Codable {
    case normal
    case verified
    case admin
}

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let role: UserRole
    let displayName: String
    var profileImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case role
        case displayName
        case profileImageUrl
    }
}
