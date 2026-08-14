import SwiftUI

// MARK: - CryoTag
// A pill-shaped badge used for language tags, status indicators, and
// metadata labels. The `.status` style prepends a colored dot indicator.
// Uses a monospaced font for a clean, data-driven appearance.

struct CryoTag: View {
    let text: String
    let color: Color
    let style: TagStyle

    enum TagStyle {
        /// A simple pill badge with colored text and border.
        case standard
        /// A status badge with a filled dot indicator preceding the text.
        case status
    }

    var body: some View {
        HStack(spacing: 6) {
            if style == .status {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }

            Text(text)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .textCase(.uppercase)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Convenience Initializers

extension CryoTag {

    /// Creates a standard CryoTag using the theme's accent color.
    /// - Parameters:
    ///   - text:    The label text displayed inside the pill.
    ///   - manager: The current ThemeManager for accent color resolution.
    init(text: String, manager: ThemeManager) {
        self.text = text
        self.color = CryoColors.accent(manager)
        self.style = .standard
    }

    /// Creates a status CryoTag with a custom indicator color.
    /// - Parameters:
    ///   - text:        The label text displayed inside the pill.
    ///   - statusColor: The color for the dot indicator, text, and border.
    ///   - manager:     The current ThemeManager (reserved for future use).
    init(text: String, statusColor: Color, manager: ThemeManager) {
        self.text = text
        self.color = statusColor
        self.style = .status
    }
}
