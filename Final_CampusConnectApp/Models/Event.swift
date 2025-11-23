import Foundation
import FirebaseFirestore

enum EventStatus: String, Codable {
    case pending
    case approved
    case rejected
}

enum EventFaculty: String, Codable, CaseIterable {
    case education = "Education"
    case humanities = "Humanities"
    case science = "Science"
    case socialSciences = "Social Sciences"
    case physicalEducation = "Physical Education"
    case engineering = "Engineering"
    case fineArts = "Fine Arts"
    case medicine = "Medicine"
    case other = "Other"
}

enum EventCategory: String, Codable, CaseIterable {
    case academic = "Academic"
    case recreation = "Recreation"
    case workshop = "Workshop"
    case seminar = "Seminar"
    case sports = "Sports"
    case other = "Other"
}

struct Event: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let imageUrl: String
    let location: String
    let eventDate: Date
    let createBy: String
    let faculty: EventFaculty
    let category: EventCategory
    var status: EventStatus
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case imageUrl
        case location
        case eventDate
        case createBy
        case faculty
        case category
        case status
        case createdAt
    }
}
