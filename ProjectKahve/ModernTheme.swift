import SwiftUI

struct ModernTheme {
    // Primary color palette - Vibrant pastels
    static let sage = Color(hex: "B4D4B5")        // Soft pastel green
    static let mint = Color(hex: "D0F0C0")        // Light mint
    static let peach = Color(hex: "FFCBA4")       // Soft peach
    static let lavender = Color(hex: "E6E6FA")    // Light lavender
    static let coral = Color(hex: "FFB5A7")       // Pastel coral
    
    // Base colors
    static let background = Color(hex: "F8F9FA")  // Clean background
    static let surface = Color(hex: "FFFFFF")     // Pure white
    static let textPrimary = Color(hex: "2C3E50") // Deep blue-gray
    static let textSecondary = Color(hex: "95A5A6") // Muted gray
    
    // Gradient presets
    static let peachToMint = LinearGradient(
        colors: [peach.opacity(0.3), mint.opacity(0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let sageToLavender = LinearGradient(
        colors: [sage.opacity(0.4), lavender.opacity(0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let primaryGradient = LinearGradient(
        colors: [sage, sage.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Typography
    struct Typography {
        static let largeTitle = Font.custom("SF Pro Rounded", size: 34).weight(.bold)
        static let title = Font.custom("SF Pro Rounded", size: 28).weight(.semibold)
        static let headline = Font.custom("SF Pro Rounded", size: 20).weight(.medium)
        static let body = Font.custom("SF Pro Rounded", size: 16)
        static let caption = Font.custom("SF Pro Rounded", size: 14)
    }
}

// Custom modifiers
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ModernTheme.surface)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 5)
    }
}

struct InteractiveCardModifier: ViewModifier {
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .background(ModernTheme.surface)
            .cornerRadius(24)
            .shadow(
                color: isSelected ? ModernTheme.sage.opacity(0.3) : Color.black.opacity(0.06),
                radius: isSelected ? 20 : 15,
                x: 0,
                y: isSelected ? 8 : 5
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

struct PrimaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ModernTheme.sage)
            .cornerRadius(16)
            .shadow(color: ModernTheme.sage.opacity(0.3), radius: 10, x: 0, y: 4)
    }
}

struct SecondaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ModernTheme.surface)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

// Extension for applying modifiers
extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
    
    func interactiveCardStyle(isSelected: Bool = false) -> some View {
        modifier(InteractiveCardModifier(isSelected: isSelected))
    }
    
    func primaryButtonStyle() -> some View {
        modifier(PrimaryButtonModifier())
    }
    
    func secondaryButtonStyle() -> some View {
        modifier(SecondaryButtonModifier())
    }
}

// Helper for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: CGFloat
        switch hex.count {
        case 3:
            (r, g, b) = (
                CGFloat((int >> 8) & 0xFF) / 255,
                CGFloat((int >> 4) & 0xFF) / 255,
                CGFloat(int & 0xFF) / 255
            )
        case 6:
            (r, g, b) = (
                CGFloat((int >> 16) & 0xFF) / 255,
                CGFloat((int >> 8) & 0xFF) / 255,
                CGFloat(int & 0xFF) / 255
            )
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(red: r, green: g, blue: b)
    }
}
