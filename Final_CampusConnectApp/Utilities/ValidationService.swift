import Foundation

class ValidationService {
    
    // ฟังก์ชันเช็คว่าอีเมลถูกต้องตามรูปแบบ มศว หรือไม่
    static func isValidSWUEmail(_ email: String) -> Bool {
        // 1. ต้องไม่ว่างเปล่า
        guard !email.isEmpty else { return false }
        
        // 2. ต้องลงท้ายด้วย @g.swu.ac.th
        return email.lowercased().hasSuffix("@g.swu.ac.th")
    }
    
    // ฟังก์ชันเช็คความยาวรหัสผ่าน (สมมติขั้นต่ำ 6 ตัว)
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
}
