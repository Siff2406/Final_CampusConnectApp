import Foundation
import FirebaseFirestore

struct BlogPost: Identifiable, Codable {
    let id: String
    let content: String
    let authorId: String
    let authorName: String
    let timestamp: Date
    var likes: Int
    var likedBy: [String]
    var commentCount: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case authorId
        case authorName
        case timestamp
        case likes
        case likedBy
        case commentCount
    }
    
    init(id: String, content: String, authorId: String, authorName: String, timestamp: Date, likes: Int, likedBy: [String], commentCount: Int = 0) {
        self.id = id
        self.content = content
        self.authorId = authorId
        self.authorName = authorName
        self.timestamp = timestamp
        self.likes = likes
        self.likedBy = likedBy
        self.commentCount = commentCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        authorId = try container.decode(String.self, forKey: .authorId)
        authorName = try container.decode(String.self, forKey: .authorName)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        likes = try container.decode(Int.self, forKey: .likes)
        likedBy = try container.decode([String].self, forKey: .likedBy)
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
    }
}
