import Foundation

struct Comment: Identifiable, Codable {
    let id: String
    let content: String
    let authorId: String
    let authorName: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case authorId
        case authorName
        case timestamp
    }
}
