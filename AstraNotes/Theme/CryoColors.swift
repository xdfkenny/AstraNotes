import SwiftUI

// MARK: - CryoColors
// Complete "Soft Cryo" color system for the AstraNotes ice-crystal aesthetic.
// Every function accepts a `ThemeManager` reference and returns the
// appropriate color for the current light / dark mode.
//
// Usage:  CryoColors.background(themeManager)
//         CryoColors.accentGlow(themeManager)

struct CryoColors {

    // ================================================================
    // MARK: - Background Colors
    // ================================================================

    /// The primary window / content background.
    static func background(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#0F1729")
            : Color(hex: "#F0F7FF")
    }

    /// A slightly warmer variant used for sidebar panels and card surfaces.
    static func backgroundWarm(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#1A2332")
            : Color(hex: "#F8FBFF")
    }

    // ================================================================
    // MARK: - Foreground Colors
    // ================================================================

    /// Primary text / icon foreground color.
    static func foreground(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#E8F4FC")
            : Color(hex: "#2C3E50")
    }

    /// Dimmed foreground for secondary labels, timestamps, and metadata.
    static func foregroundMuted(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#8BA3B8")
            : Color(hex: "#5A6D7E")
    }

    // ================================================================
    // MARK: - Accent Colors
    // ================================================================

    /// Core ice-blue accent used for buttons, links, and highlights.
    static func accent(_ manager: ThemeManager) -> Color {
        Color(hex: "#7EC8E3")
    }

    /// A lighter tint for hover states and subtle highlights.
    static func accentLight(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#A8D8EA")
            : Color(hex: "#B8E3F5")
    }

    /// A darker shade for pressed states and strong emphasis.
    static func accentDark(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#5DB8E0")
            : Color(hex: "#4A9ECF")
    }

    /// Semi-transparent glow tint used behind accent elements.
    static func accentGlow(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#7EC8E3").opacity(0.15)
            : Color(hex: "#D6F0FF")
    }

    // ================================================================
    // MARK: - Decorative Colors
    // ================================================================

    /// Pure crystal ice color for decorative shapes and snowflakes.
    static func crystal(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#7EC8E3")
            : Color(hex: "#A8D8EA")
    }

    /// Frosted glass tint for overlay surfaces.
    static func frost(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#1E3A4F")
            : Color(hex: "#E1F5FE")
    }

    /// Soft rose-ice tint used sparingly for accent differentiation.
    static func roseIce(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#C4A8B8")
            : Color(hex: "#E8D5E0")
    }

    // ================================================================
    // MARK: - Border Colors
    // ================================================================

    /// Standard 1px border color for cards and separators.
    static func border(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#2A4360")
            : Color(hex: "#C5E3F5")
    }

    /// Emphasized border for focused / selected elements.
    static func borderStrong(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#4A9ECF")
            : Color(hex: "#7EC8E3")
    }

    // ================================================================
    // MARK: - Shadow Colors
    // ================================================================

    /// Drop shadow color used behind cards and elevated surfaces.
    static func shadow(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color.black.opacity(0.3)
            : Color(hex: "#7EC8E3").opacity(0.15)
    }

    /// Glow shadow for focused or highlighted elements.
    static func shadowGlow(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#7EC8E3").opacity(0.2)
            : Color(hex: "#7EC8E3").opacity(0.25)
    }

    // ================================================================
    // MARK: - Status Colors
    // ================================================================

    /// Green for success states, completed items, and positive feedback.
    static func success(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#4ADE80")
            : Color(hex: "#22C55E")
    }

    /// Amber for warnings, approaching deadlines, and caution alerts.
    static func warning(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#FBBF24")
            : Color(hex: "#F59E0B")
    }

    /// Red for errors, failures, and destructive actions.
    static func error(_ manager: ThemeManager) -> Color {
        manager.isDark
            ? Color(hex: "#F87171")
            : Color(hex: "#EF4444")
    }

    // ================================================================
    // MARK: - Gradient Helpers
    // ================================================================

    /// Primary accent gradient (topLeading -> bottomTrailing).
    static func primaryGradient(_ manager: ThemeManager) -> LinearGradient {
        LinearGradient(
            colors: [accent(manager), accentDark(manager)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Gradient used for card backgrounds.
    static func cardGradient(_ manager: ThemeManager) -> LinearGradient {
        manager.isDark
            ? LinearGradient(
                colors: [Color(hex: "#1A2332"), Color(hex: "#1E3A4F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            : LinearGradient(
                colors: [Color(hex: "#F8FBFF"), Color(hex: "#E1F5FE")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
    }

    /// Multi-stop gradient for crystal / ice border decorations.
    static func crystalBorderGradient(_ manager: ThemeManager) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#7EC8E3"),
                Color(hex: "#B8E3F5"),
                Color(hex: "#A8D8EA")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Subtle gradient for hover / highlight states on interactive rows.
    static func hoverGradient(_ manager: ThemeManager) -> LinearGradient {
        manager.isDark
            ? LinearGradient(
                colors: [Color(hex: "#1E3A4F"), Color(hex: "#2A4360")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            : LinearGradient(
                colors: [Color(hex: "#E1F5FE"), Color(hex: "#D6F0FF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
    }
}
