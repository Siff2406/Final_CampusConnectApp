import SwiftUI

extension Color {
    // MARK: - SWU Official Colors
    static let swuRed = Color(red: 218/255, green: 33/255, blue: 40/255) // Pantone 3546 C
    static let swuGrey = Color(red: 99/255, green: 100/255, blue: 102/255) // Pantone 7547 UP
    
    // MARK: - Semantic Colors
    static let swuBackground = Color(hex: "#F9F9F9") // Slightly off-white for background
    static let swuTextPrimary = Color(hex: "#333333")
    static let swuTextSecondary = Color(hex: "#828282")
    
    // MARK: - Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
