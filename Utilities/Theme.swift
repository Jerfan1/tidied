import SwiftUI

// MARK: - Color Palette
// Dusty Rose - elegant, feminine, privacy-focused
// Unique identity that stands out

extension Color {
    // Primary backgrounds
    static let appBackground = Color(hex: "FBF8F8")        // Soft blush cream
    static let cardBackground = Color(hex: "FFFFFF")        // Pure white for cards
    
    // Accent colors - Dusty Rose
    static let rose = Color(hex: "D4A5A5")                  // Primary dusty rose
    static let roseDark = Color(hex: "B8878B")              // Deeper rose
    static let roseLight = Color(hex: "EDD9D9")             // Light rose for backgrounds
    
    // Legacy names (mapped to new colors for compatibility)
    static let sage = Color(hex: "D4A5A5")                  // Maps to rose
    static let sageDark = Color(hex: "B8878B")              // Maps to roseDark
    static let sageLight = Color(hex: "EDD9D9")             // Maps to roseLight
    
    // Warm accents
    static let blush = Color(hex: "F0E4E4")                 // Very light blush
    static let clay = Color(hex: "C9A698")                  // Warm terracotta
    
    // Text colors
    static let textPrimary = Color(hex: "2D3436")           // Almost black
    static let textSecondary = Color(hex: "636E72")         // Medium gray
    static let textTertiary = Color(hex: "B2BEC3")          // Light gray
    
    // Action colors
    static let keepGreen = Color(hex: "7EAB8E")             // Muted sage green for keep
    static let deleteRed = Color(hex: "D4A5A5")             // Rose for delete (softer)
    static let favouriteGold = Color(hex: "D4B896")         // Warm gold for favourite
    
    // Utility
    static let divider = Color(hex: "EDE8E8")
    
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
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
// Clean, elegant fonts

extension Font {
    // Headers - using system serif for elegance
    static let titleLarge = Font.system(size: 32, weight: .semibold, design: .serif)
    static let titleMedium = Font.system(size: 24, weight: .semibold, design: .serif)
    static let titleSmall = Font.system(size: 18, weight: .medium, design: .serif)
    
    // Body - clean sans-serif
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    
    // Labels
    static let labelLarge = Font.system(size: 15, weight: .semibold, design: .default)
    static let labelMedium = Font.system(size: 13, weight: .semibold, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
    
    // Special
    static let counter = Font.system(size: 14, weight: .medium, design: .monospaced)
}

// MARK: - Spacing
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 24
}

