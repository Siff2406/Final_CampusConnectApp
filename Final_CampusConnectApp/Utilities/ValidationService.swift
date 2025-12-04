import Foundation

class ValidationService {
    
    static func isValidSWUEmail(_ email: String) -> Bool {

        guard !email.isEmpty else { return false }
        return email.lowercased().hasSuffix("@g.swu.ac.th")
    }
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
}
