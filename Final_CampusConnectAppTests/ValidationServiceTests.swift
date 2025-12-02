import XCTest
@testable import Final_CampusConnectApp // ชื่อโปรเจกต์ของคุณ

final class ValidationServiceTests: XCTestCase {

    // เทสกรณีอีเมลถูกต้อง
    func testValidSWUEmail() {
        let email = "student64@g.swu.ac.th"
        let isValid = ValidationService.isValidSWUEmail(email)
        XCTAssertTrue(isValid, "อีเมล @g.swu.ac.th ควรจะผ่านการตรวจสอบ")
    }
    
    // เทสกรณีอีเมลผิด (Gmail)
    func testInvalidGmail() {
        let email = "student@gmail.com"
        let isValid = ValidationService.isValidSWUEmail(email)
        XCTAssertFalse(isValid, "อีเมล @gmail.com ต้องไม่ผ่านการตรวจสอบ")
    }
    
    // เทสกรณีอีเมลผิด (ไม่มีโดเมน)
    func testInvalidFormat() {
        let email = "student64"
        let isValid = ValidationService.isValidSWUEmail(email)
        XCTAssertFalse(isValid, "อีเมลที่ไม่มี @ ต้องไม่ผ่าน")
    }
    
    // เทสกรณีรหัสผ่านสั้นเกินไป
    func testShortPassword() {
        let password = "123"
        let isValid = ValidationService.isValidPassword(password)
        XCTAssertFalse(isValid, "รหัสผ่านสั้นกว่า 6 ตัวต้องไม่ผ่าน")
    }
    
    // เทสกรณีรหัสผ่านถูกต้อง
    func testValidPassword() {
        let password = "password123"
        let isValid = ValidationService.isValidPassword(password)
        XCTAssertTrue(isValid, "รหัสผ่าน 6 ตัวขึ้นไปควรผ่าน")
    }
}
