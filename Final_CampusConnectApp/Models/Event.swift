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
    case nursing = "Nursing"
    case dentistry = "Dentistry"
    case pharmacy = "Pharmacy"
    case physicalTherapy = "Physical Therapy"
    case economics = "Economics"
    case cosci = "COSCI"
    case bodhiwichalai = "Bodhiwichalai College"
    case swuIC = "SWUIC"
    case cci = "CCI"
    case business = "Business School"
    case ece = "Environmental Culture and Ecotourism"
    case ai = "Agricultural Product Technology and Innovation"
    case other = "Other"
}

enum EventCategory: String, Codable, CaseIterable {
    case academic = "Academic"
    case competition = "Competition"
    case openHouse = "Open House"
    case recreation = "Recreation"
    case workshop = "Workshop"
    case seminar = "Seminar"
    case sports = "Sports"
    case concert = "Concert"
    case community = "Community"
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
    var interestedCount: Int = 0 // Added interestedCount with default 0
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
        case interestedCount
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        location = try container.decode(String.self, forKey: .location)
        eventDate = try container.decode(Date.self, forKey: .eventDate)
        createBy = try container.decode(String.self, forKey: .createBy)
        faculty = try container.decode(EventFaculty.self, forKey: .faculty)
        category = try container.decode(EventCategory.self, forKey: .category)
        status = try container.decode(EventStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // Handle missing interestedCount for old data
        interestedCount = try container.decodeIfPresent(Int.self, forKey: .interestedCount) ?? 0
    }
    
    // Memberwise init for creating new events locally
    init(id: String, title: String, description: String, imageUrl: String, location: String, eventDate: Date, createBy: String, faculty: EventFaculty, category: EventCategory, status: EventStatus, interestedCount: Int = 0, createdAt: Date) {
        self.id = id
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.location = location
        self.eventDate = eventDate
        self.createBy = createBy
        self.faculty = faculty
        self.category = category
        self.status = status
        self.interestedCount = interestedCount
        self.createdAt = createdAt
    }
}
