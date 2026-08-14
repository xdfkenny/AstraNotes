//
//  DesignTokens.swift
//  AstraNotes
//
//  Single source of truth for the AstraNotes design system.
//  No hardcoded hex, sizes, or fonts in views. Import this file only.
//
//  Spec: AstraNotes/DesignSystem/DESIGN.md
//  Colors resolve adaptively (light/dark) against the system appearance.
//

import SwiftUI

// MARK: - Color Tokens

extension Color {
    // MARK: Accent (single accent, locked: Astra Teal)
    static let accent = Color(light: "#0B7A6E", dark: "#59C9B8")
    static let accentContainer = Color.accent.opacity(0.12)
    static let onAccent = Color(light: "#FFFFFF", dark: "#06251F")

    // MARK: Semantic (state only)
    static let semanticDanger = Color(light: "#D64545", dark: "#FF6B6B")
    static let semanticWarning = Color(light: "#C77E1F", dark: "#E8A44C")
    static let semanticSuccess = Color(light: "#1E8E5A", dark: "#4BC48C")

    // MARK: Neutrals (one family, adaptive)
    static let surfaceBackground = Color(light: "#F7F7F8", dark: "#131316")
    static let surface = Color(light: "#FFFFFF", dark: "#1C1C1F")
    static let surfaceElevated = Color(light: "#FFFFFF", dark: "#242428")
    static let hairline = Color(light: "#000000", dark: "#FFFFFF").opacity(0.10)
    static let textPrimary = Color(light: "#1A1A1E", dark: "#F2F2F4")
    static let textSecondary = Color(light: "#5C5C66", dark: "#A0A0AA")
    static let textTertiary = Color(light: "#8E8E98", dark: "#6E6E78")

    // MARK: Subject groups (muted, semantic distinction only)
    static let group1 = Color(light: "#B4574E", dark: "#D98A83")
    static let group2 = Color(light: "#2E6BA8", dark: "#7BB3E8")
    static let group3 = Color(light: "#8A6D2F", dark: "#C9A85C")
    static let group4 = Color(light: "#2E7D6E", dark: "#6FC3B2")
    static let group5 = Color(light: "#5A5CA8", dark: "#A2A4E8")
    static let group6 = Color(light: "#A04A7D", dark: "#D88FB4")
    static let groupCore = Color(light: "#4A5568", dark: "#8B95A7")

    /// Muted roundel background for an IB subject group (18% alpha).
    static func groupContainer(_ group: Int) -> Color {
        groupColor(group).opacity(0.18)
    }

    /// The muted semantic color for an IB subject group.
    static func groupColor(_ group: Int) -> Color {
        switch group {
        case 1: return .group1
        case 2: return .group2
        case 3: return .group3
        case 4: return .group4
        case 5: return .group5
        case 6: return .group6
        default: return .groupCore
        }
    }
}

// MARK: - ShapeStyle Color Members
// Lets `.foregroundStyle(.textSecondary)` resolve: SwiftUI looks for static
// members on `ShapeStyle`, so mirror the semantic text colors there.

extension ShapeStyle where Self == Color {
    static var textPrimary: Color { .textPrimary }
    static var textSecondary: Color { .textSecondary }
    static var textTertiary: Color { .textTertiary }
}

// MARK: - Typography Tokens

extension Font {
    /// SF Pro Rounded display font (friendly, scholarly; display only).
    static func astraDisplay(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// SF Pro body font.
    static func astraBody(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// SF Mono for all data: timers, counts, timestamps, word counts.
    static func astraMono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

enum TypeScale {
    static let display: Font = .astraDisplay(28, .semibold)
    static let title: Font = .astraDisplay(22, .semibold)
    static let heading: Font = .astraDisplay(17, .semibold)
    static let subheading: Font = .astraBody(15, .semibold)
    static let body: Font = .astraBody(13)
    static let bodyLarge: Font = .astraBody(15)
    static let caption: Font = .astraBody(11)
    static let micro: Font = .astraBody(10, .medium)
}

// MARK: - Spacing Tokens

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
}

// MARK: - Radius Tokens (shape consistency lock)

enum Radius {
    static let micro: CGFloat = 6
    static let control: CGFloat = 8
    static let card: CGFloat = 12
    static let panel: CGFloat = 16
    /// Inner radius for double-bezel cards (outer - padding).
    static let cardInner: CGFloat = card - 2
    static let panelInner: CGFloat = panel - 2
}

// MARK: - Layout Tokens

/// Named `LayoutTokens` (not `Layout`) to avoid shadowing SwiftUI's `Layout` protocol,
/// which is required by custom `Layout` conformances (e.g. FlowLayout in CASJournalView).
enum LayoutTokens {
    static let sidebarWidth: CGFloat = 240
    static let inspectorWidth: CGFloat = 300
    static let contentMaxWidth: CGFloat = 640
    static let minWindowWidth: CGFloat = 960
    static let minWindowHeight: CGFloat = 640
    static let cardPadding: CGFloat = 14
}

// MARK: - Motion Tokens

enum Motion {
    /// Press feedback: scale to 0.97, 100ms.
    static let pressScale: CGFloat = 0.97
    static let pressDuration: Double = 0.1
    static let releaseDuration: Double = 0.2

    /// Standard UI spring.
    static let standard = Animation.spring(response: 0.32, dampingFraction: 0.86)

    /// Entrance spring with slight bounce for hero elements.
    static let entrance = Animation.spring(response: 0.35, dampingFraction: 0.8)

    /// Fast state-change fade.
    static let stateChange = Animation.easeOut(duration: 0.15)

    /// Waveform bar spring.
    static let waveform = Animation.spring(response: 0.15, dampingFraction: 0.7)

    /// Flashcard flip spring.
    static let flip = Animation.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)
}
