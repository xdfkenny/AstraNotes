import SwiftUI
import Foundation

// MARK: - Color Hex Initializer
// Allows creating a Color from a hex string: Color(hex: "#7EC8E3").
// Supports 3-character (RGB), 6-character (RRGGBB), and 8-character
// (AARRGGBB) hex strings.

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        let r: Double
        let g: Double
        let b: Double
        let a: Double

        switch cleaned.count {
        case 3: // RGB (12-bit)  e.g. "FFF"
            r = Double((int >> 8) & 0xF) * 17 / 255
            g = Double((int >> 4) & 0xF) * 17 / 255
            b = Double(int & 0xF) * 17 / 255
            a = 1.0
        case 6: // RRGGBB (24-bit)  e.g. "7EC8E3"
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
            a = 1.0
        case 8: // AARRGGBB (32-bit)  e.g. "FF7EC8E3"
            a = Double((int >> 24) & 0xFF) / 255
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0; a = 1
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Hexagon Shape
// A regular hexagon centered in its frame. Useful for ice-crystal
// decorative elements in the Soft Cryo theme.

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width  = rect.width
        let height = rect.height
        let center = CGPoint(x: width / 2, y: height / 2)
        let radius = min(width, height) / 2

        var path = Path()
        for i in 0..<6 {
            let angle = Angle.degrees(Double(i) * 60 - 30)
            let x = center.x + radius * CGFloat(cos(angle.radians))
            let y = center.y + radius * CGFloat(sin(angle.radians))
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Diamond Shape
// A 45-degree rotated square used for crystal shard decorations.

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let hw = rect.width / 2
        let hh = rect.height / 2

        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - hh))       // top
        path.addLine(to: CGPoint(x: center.x + hw, y: center.y))      // right
        path.addLine(to: CGPoint(x: center.x, y: center.y + hh))      // bottom
        path.addLine(to: CGPoint(x: center.x - hw, y: center.y))      // left
        path.closeSubpath()
        return path
    }
}

// MARK: - Date Extensions
// Formatting helpers that cover the most common date display patterns
// used throughout the app.

extension Date {

    /// Formats the date with the given format string.
    func formatted(_ format: String = "yyyy-MM-dd") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    /// Returns just the time portion, e.g. "14:35:02".
    var timeString: String {
        formatted("HH:mm:ss")
    }

    /// Short human-readable date, e.g. "Aug 13, 2026".
    var shortDateString: String {
        formatted("MMM d, yyyy")
    }

    /// ISO-compatible date string, e.g. "2026-08-13".
    var fileDateString: String {
        formatted("yyyy-MM-dd")
    }

    /// Relative description such as "2 hours ago" or "yesterday".
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Whether the date is today (calendar-day comparison).
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Whether the date falls within the current week.
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
}

// MARK: - String Extensions
// Convenience properties for string manipulation used in notes,
// transcription results, and UI labels.

extension String {

    /// Whitespace-and-newline trimmed copy.
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Split into an array of lines.
    var lines: [String] {
        components(separatedBy: .newlines)
    }

    /// Approximate word count based on whitespace splitting.
    var wordCount: Int {
        components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    /// Character count (ignoring whitespace and newlines).
    var characterCount: Int {
        replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .count
    }

    /// Returns the string truncated to `length` characters with an ellipsis.
    func truncated(to length: Int) -> String {
        if count > length {
            return String(prefix(length)) + "\u{2026}"
        }
        return self
    }

    /// Returns the string in title case.
    var titleCased: String {
        split(separator: " ")
            .map { word in
                if word.first?.isLetter == true {
                    return word.prefix(1).uppercased() + word.dropFirst().lowercased()
                }
                return String(word)
            }
            .joined(separator: " ")
    }

    /// True when the string is empty or only contains whitespace.
    var isBlank: Bool {
        trimmed.isEmpty
    }
}

// MARK: - View Extensions
// Shared modifiers that apply the Soft Cryo card and hover styles.

extension View {

    /// Applies the standard cryo card treatment: warm background, rounded
    /// corners, border, and subtle drop shadow.
    func cryoCardStyle(_ manager: ThemeManager) -> some View {
        self
            .background(CryoColors.backgroundWarm(manager))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(CryoColors.border(manager), lineWidth: 1)
            )
            .shadow(color: CryoColors.shadow(manager), radius: 8, x: 0, y: 2)
    }

    /// Applies the cryo card style with a custom corner radius.
    func cryoCardStyle(_ manager: ThemeManager, cornerRadius: CGFloat) -> some View {
        self
            .background(CryoColors.backgroundWarm(manager))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(CryoColors.border(manager), lineWidth: 1)
            )
            .shadow(color: CryoColors.shadow(manager), radius: 8, x: 0, y: 2)
    }

    /// Wraps the view in a subtle hover animation container.
    func cryoHoverEffect(_ manager: ThemeManager) -> some View {
        #if os(macOS)
        self.onHover { isHovered in
            withAnimation(.easeOut(duration: 0.2)) {
                // Intentional no-op; individual views add visual feedback.
            }
        }
        #else
        self
        #endif
    }

    /// Conditional modifier helper that only applies the modifier
    /// when `condition` is true.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool,
                              transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Bundle Extensions

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var fullVersion: String {
        "\(appVersion) (\(buildNumber))"
    }
}

// MARK: - Array Extensions

extension Array {
    /// Safely access an element by index, returning nil if out of bounds.
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
