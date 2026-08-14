import SwiftUI

// MARK: - CryoCard Style
// Enumerates the visual treatments for CryoCard containers.
// - standard:  Warm frost panel with subtle border and shadow.
// - featured:  Crystal border gradient with elevated glow effect.
// - status:    Dashboard widget with gradient background and padding.

enum CryoCardStyle {
    case standard
    case featured
    case status
}

// MARK: - CryoCard
// A reusable card container that wraps child content in a Soft Cryo
// styled panel. The card style determines the background, border,
// shadow, and hover behavior. A default padding of 24pt is applied
// internally, overridable through the convenience initializer.

struct CryoCard<Content: View>: View {
    let manager: ThemeManager
    let style: CryoCardStyle
    let internalPadding: CGFloat
    @ViewBuilder let content: () -> Content
    @State private var isHovered = false

    init(manager: ThemeManager, style: CryoCardStyle = .standard, padding: CGFloat = 24, @ViewBuilder content: @escaping () -> Content) {
        self.manager = manager
        self.style = style
        self.internalPadding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(internalPadding)
            .cardAppearance(for: style, manager: manager)
#if os(macOS)
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
#endif
    }

    // MARK: - Card Appearance

    @ViewBuilder
    private func cardAppearance(for style: CryoCardStyle, manager: ThemeManager) -> some View {
        switch style {
        case .standard:
            self.background(CryoColors.backgroundWarm(manager))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(CryoColors.border(manager), lineWidth: 1)
                )
                .shadow(
                    color: isHovered ? CryoColors.shadowGlow(manager) : CryoColors.shadow(manager),
                    radius: isHovered ? 16 : 8,
                    x: 0,
                    y: isHovered ? -2 : 2
                )

        case .featured:
            self.background(manager.isDark ? Color(hex: "#1A2332") : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            CryoColors.crystalBorderGradient(manager),
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: CryoColors.shadowGlow(manager),
                    radius: isHovered ? 24 : 20,
                    x: 0,
                    y: 0
                )
                .scaleEffect(isHovered ? 1.01 : 1.0)

        case .status:
            self.background(CryoColors.cardGradient(manager))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(CryoColors.border(manager), lineWidth: 1)
                )
        }
    }
}
