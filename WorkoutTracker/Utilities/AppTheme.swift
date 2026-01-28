import SwiftUI

/// Dark Theme Fitness App System
/// Black background with blue and multi-color accents
enum AppTheme {

    // MARK: - Color Palette (Dark Theme)

    /// Primary blue accent color
    static let primaryBlue = Color(hex: "5B7FE8")

    /// Additional accent colors
    static let accentOrange = Color(hex: "FF6B35")
    static let accentPurple = Color(hex: "A855F7") // Vibrant purple from image
    static let accentGreen = Color(hex: "10B981") // Bright green from image
    static let accentTeal = Color(hex: "4ECDC4")

    /// Main accent (for backwards compatibility)
    static let neonGreen = Color(hex: "5B7FE8") // Now blue

    /// Orange accent for labels
    static let orangeAccent = Color(hex: "FF6B35")

    /// Dark backgrounds
    static let darkBackground = Color(hex: "000000")
    static let cardBackground = Color(hex: "1A1A1A")
    static let cardBackgroundSecondary = Color(hex: "252525")

    /// Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "A0A0A0")
    static let textSecondaryLight = Color(hex: "999999")
    static let textTertiary = Color(hex: "666666")

    /// Additional backgrounds
    static let progressTrackBackground = Color(hex: "2A2A2A")

    /// Primary flat colors (now blue)
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "5B7FE8")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let secondaryGradient = LinearGradient(
        colors: [Color(hex: "A855F7")], // Vibrant Purple
        startPoint: .leading,
        endPoint: .trailing
    )

    static let accentGradient = LinearGradient(
        colors: [Color(hex: "10B981")], // Bright Green
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let energyGradient = LinearGradient(
        colors: [Color(hex: "FF6B35")], // Orange
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Muscle Group Flat Colors

    static func muscleGroupGradient(for exerciseName: String) -> LinearGradient {
        let lowerName = exerciseName.lowercased()

        // Chest: Blue
        if lowerName.contains("bench") || lowerName.contains("chest") ||
           lowerName.contains("fly") || lowerName.contains("press") && lowerName.contains("chest") {
            return LinearGradient(
                colors: [Color(hex: "5B7FE8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // Legs: Orange
        if lowerName.contains("squat") || lowerName.contains("leg") ||
           lowerName.contains("lunge") || lowerName.contains("deadlift") ||
           lowerName.contains("calf") || lowerName.contains("hip") {
            return LinearGradient(
                colors: [Color(hex: "FF6B35")],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        // Back: Green
        if lowerName.contains("row") || lowerName.contains("pull") ||
           lowerName.contains("lat") || lowerName.contains("deadlift") {
            return LinearGradient(
                colors: [Color(hex: "10B981")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // Shoulders: Purple
        if lowerName.contains("shoulder") || lowerName.contains("lateral") ||
           lowerName.contains("overhead") || lowerName.contains("shrug") ||
           lowerName.contains("raise") {
            return LinearGradient(
                colors: [Color(hex: "A855F7")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // Arms: Blue
        if lowerName.contains("curl") || lowerName.contains("tricep") ||
           lowerName.contains("bicep") || lowerName.contains("arm") {
            return LinearGradient(
                colors: [Color(hex: "5B7FE8")],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        // Default: Blue
        return primaryGradient
    }

    // MARK: - Stat Type Flat Colors

    static let volumeGradient = LinearGradient(
        colors: [Color(hex: "10B981")], // Green
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let workoutCountGradient = LinearGradient(
        colors: [Color(hex: "5B7FE8")], // Blue
        startPoint: .leading,
        endPoint: .trailing
    )

    static let durationGradient = LinearGradient(
        colors: [Color(hex: "FF6B35")], // Orange
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let prGradient = LinearGradient(
        colors: [Color(hex: "A855F7")], // Purple
        startPoint: .leading,
        endPoint: .trailing
    )

    static let streakGradient = LinearGradient(
        colors: [Color(hex: "A855F7")], // Purple
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Solid Colors (for icons, text accents)

    static let electricBlue = Color(hex: "5B7FE8")
    static let vibrantPurple = Color(hex: "A855F7")
    static let hotPink = Color(hex: "FF6B35")
    static let energyOrange = Color(hex: "FF6B35")
    static let successGreen = Color(hex: "10B981") // Bright green
    static let goldPR = Color(hex: "A855F7") // Purple for PRs
    static let cyan = Color(hex: "4ECDC4")

    // MARK: - Background Elements

    /// Subtle glowing orbs for depth
    static func backgroundOrb(color: Color, size: CGFloat = 200, blur: CGFloat = 60) -> some View {
        Circle()
            .fill(color.opacity(0.05))
            .frame(width: size, height: size)
            .blur(radius: blur)
    }

    // MARK: - Design Constants

    enum Layout {
        static let cardCornerRadius: CGFloat = 16
        static let smallCornerRadius: CGFloat = 12
        static let buttonCornerRadius: CGFloat = 12
        static let chipCornerRadius: CGFloat = 8

        static let cardPadding: CGFloat = 16
        static let screenPadding: CGFloat = 16
        static let cardSpacing: CGFloat = 12

        static let shadowRadius: CGFloat = 0
        static let shadowOpacity: CGFloat = 0
    }

    enum Typography {
        // Dynamic Type sizes
        static let heroNumber: Font = .system(size: 48, weight: .semibold, design: .rounded)
        static let largeTitle: Font = .system(size: 34, weight: .medium, design: .rounded)
        static let title1: Font = .system(size: 28, weight: .medium, design: .rounded)
        static let title2: Font = .system(size: 22, weight: .medium, design: .rounded)
        static let headline: Font = .system(size: 17, weight: .medium, design: .rounded)
        static let body: Font = .system(size: 17, weight: .regular, design: .default)
        static let callout: Font = .system(size: 16, weight: .regular, design: .default)
        static let caption: Font = .system(size: 13, weight: .regular, design: .rounded)
        static let smallLabel: Font = .system(size: 11, weight: .semibold, design: .rounded)
    }

    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
        static let snappy = SwiftUI.Animation.snappy(duration: 0.3)
        static let smooth = SwiftUI.Animation.smooth(duration: 0.4)
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
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

// MARK: - Dark Card Background Modifier

struct GradientCardBackground: ViewModifier {
    let gradient: LinearGradient
    let opacity: Double

    init(gradient: LinearGradient, opacity: Double = 1.0) {
        self.gradient = gradient
        self.opacity = opacity
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius)
                    .fill(gradient.opacity(opacity))
            )
    }
}

extension View {
    func gradientCardBackground(_ gradient: LinearGradient, opacity: Double = 1.0) -> some View {
        modifier(GradientCardBackground(gradient: gradient, opacity: opacity))
    }

    func darkCardBackground() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius)
                .fill(AppTheme.cardBackground)
        )
    }
}
