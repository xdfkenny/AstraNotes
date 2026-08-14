import SwiftUI

// MARK: - Cryo Button Style
// Enumerates the visual styles available for CryoButton.
// - primary:   Ice-crystal pill with a gradient fill and glow shadow.
// - secondary: Frost-border outline capsule.
// - ghost:     Minimal text link with underline on hover.
// - icon:      Circular icon button with optional custom size.

enum CryoButtonStyle {
    case primary
    case secondary
    case ghost
    case icon(size: CGFloat = 40)
}

// MARK: - CryoButton
// A reusable button component that applies the Soft Cryo aesthetic.
// Supports text, icon, and custom content labels through convenience
// initializers. Hover effects are animated with a smooth ease-out curve.

struct CryoButton: View {
    let style: CryoButtonStyle
    let label: AnyView
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            label
                .buttonLabel(for: style, isHovered: isHovered)
        }
        .buttonStyle(.plain)
#if os(macOS)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
#endif
    }
}

// MARK: - Convenience Initializers

extension CryoButton {

    /// Creates a text-based CryoButton.
    /// - Parameters:
    ///   - text:   The button label text.
    ///   - style:  The visual style (defaults to `.primary`).
    ///   - action: The closure to execute when tapped.
    init(_ text: String, style: CryoButtonStyle = .primary, action: @escaping () -> Void) {
        self.style = style
        self.label = AnyView(
            Text(text)
                .font(.system(size: 14, weight: .semibold))
        )
        self.action = action
    }

    /// Creates an icon-based CryoButton.
    /// - Parameters:
    ///   - icon:   The SF Symbol name.
    ///   - style:  The visual style (defaults to `.icon()`).
    ///   - action: The closure to execute when tapped.
    init(icon: String, style: CryoButtonStyle = .icon(), action: @escaping () -> Void) {
        self.style = style
        self.label = AnyView(
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
        )
        self.action = action
    }

    /// Creates a CryoButton with arbitrary view content.
    /// - Parameters:
    ///   - content: A ViewBuilder producing the button label.
    ///   - style:   The visual style (defaults to `.primary`).
    ///   - action:  The closure to execute when tapped.
    init(@ViewBuilder content: () -> some View, style: CryoButtonStyle = .primary, action: @escaping () -> Void) {
        self.style = style
        self.label = AnyView(content())
        self.action = action
    }
}

// MARK: - Label Styling
// Applies the appropriate visual treatment for each CryoButtonStyle,
// including gradients, borders, shadows, and hover animations.

extension View {

    @ViewBuilder
    func buttonLabel(for style: CryoButtonStyle, isHovered: Bool) -> some View {
        switch style {
        case .primary:
            self
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#7EC8E3"), Color(hex: "#4A9ECF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(
                    color: Color(hex: "#7EC8E3").opacity(isHovered ? 0.35 : 0.25),
                    radius: isHovered ? 12 : 8,
                    x: 0,
                    y: 4
                )
                .scaleEffect(isHovered ? 1.03 : 1.0)

        case .secondary:
            self
                .foregroundColor(Color(hex: "#4A9ECF"))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.clear)
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "#7EC8E3"), lineWidth: 1.5)
                        )
                )
                .background(isHovered ? Color(hex: "#E1F5FE").opacity(0.3) : .clear)
                .clipShape(Capsule())

        case .ghost:
            self
                .foregroundColor(Color(hex: "#5A6D7E"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isHovered ? Color(hex: "#4A9ECF").opacity(0.1) : .clear)
                .underline(isHovered ? true : false, color: Color(hex: "#4A9ECF"))

        case .icon(let size):
            self
                .foregroundColor(Color(hex: "#4A9ECF"))
                .frame(width: size, height: size)
                .background(Color(hex: "#F8FBFF"))
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color(hex: "#C5E3F5"), lineWidth: 1)
                )
                .shadow(
                    color: Color(hex: "#7EC8E3").opacity(isHovered ? 0.2 : 0),
                    radius: isHovered ? 8 : 0
                )
                .scaleEffect(isHovered ? 1.05 : 1.0)
        }
    }
}
