import Foundation
import EventKit
import UIKit

class CalendarManager {
    static let shared = CalendarManager()
    private let eventStore = EKEventStore()
    
    private init() {}
    
    func addEventToCalendar(title: String, description: String, location: String, startDate: Date, completion: @escaping (Result<Bool, Error>) -> Void) {
        
        // 1. Request Access
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                self?.handleAccess(granted: granted, error: error, title: title, description: description, location: location, startDate: startDate, completion: completion)
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                self?.handleAccess(granted: granted, error: error, title: title, description: description, location: location, startDate: startDate, completion: completion)
            }
        }
    }
    
    private func handleAccess(granted: Bool, error: Error?, title: String, description: String, location: String, startDate: Date, completion: @escaping (Result<Bool, Error>) -> Void) {
        DispatchQueue.main.async {
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if !granted {
                let error = NSError(domain: "CalendarService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Calendar access denied"])
                completion(.failure(error))
                return
            }
            
            // 2. Create Event
            let event = EKEvent(eventStore: self.eventStore)
            event.title = title
            event.notes = description
            event.location = location
            event.startDate = startDate
            event.endDate = startDate.addingTimeInterval(2 * 60 * 60)
            event.calendar = self.eventStore.defaultCalendarForNewEvents
            let alarm = EKAlarm(relativeOffset: -1800)
            event.addAlarm(alarm)
            
            do {
                try self.eventStore.save(event, span: .thisEvent)
                completion(.success(true))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
