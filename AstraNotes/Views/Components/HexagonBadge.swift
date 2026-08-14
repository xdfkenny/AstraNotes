import SwiftUI

// MARK: - HexagonBadge
// A hexagonal clip-path badge filled with the primary Cryo gradient.
// Used for dashboard stats, progress indicators, and section header icons.

struct HexagonBadge<Content: View>: View {
    let size: CGFloat
    let manager: ThemeManager
    @ViewBuilder let content: () -> Content

    init(size: CGFloat, manager: ThemeManager, @ViewBuilder content: @escaping () -> Content) {
        self.size = size
        self.manager = manager
        self.content = content
    }

    var body: some View {
        content()
            .frame(width: size, height: size)
            .background(CryoColors.primaryGradient(manager))
            .clipShape(HexagonShape())
            .shadow(color: CryoColors.shadowGlow(manager), radius: 8, x: 0, y: 2)
    }
}

// MARK: - HexagonDisplayBadge
// A larger hexagonal badge with an optional animated crystal border glow.
// When `isFeatured` is true, a pulsing gradient stroke surrounds the badge.

struct HexagonDisplayBadge<Content: View>: View {
    let size: CGFloat
    let manager: ThemeManager
    let isFeatured: Bool
    @ViewBuilder let content: () -> Content
    @State private var glowActive = false

    init(
        size: CGFloat,
        manager: ThemeManager,
        isFeatured: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.size = size
        self.manager = manager
        self.isFeatured = isFeatured
        self.content = content
    }

    var body: some View {
        ZStack {
            // Featured: animated outer crystal border
            if isFeatured {
                HexagonShape()
                    .stroke(
                        CryoColors.crystalBorderGradient(manager),
                        lineWidth: 2
                    )
                    .frame(width: size + 8, height: size + 8)
                    .shadow(
                        color: CryoColors.shadowGlow(manager),
                        radius: glowActive ? 16 : 8
                    )
            }

            content()
                .frame(width: size, height: size)
                .background(CryoColors.primaryGradient(manager))
                .clipShape(HexagonShape())
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowActive = true
            }
        }
    }
}
