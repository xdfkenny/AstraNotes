import SwiftUI
import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

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

    /// Adaptive color that resolves light/dark hex variants against the
    /// current system appearance (respects preferredColorScheme).
    /// Usage: `Color(light: "#FFFFFF", dark: "#131316")`
    init(light: String, dark: String) {
        #if os(macOS)
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hexString: isDark ? dark : light) ?? .systemGray
        })
        #else
        self.init(uiColor: UIColor { trait in
            UIColor(hexString: trait.userInterfaceStyle == .dark ? dark : light) ?? .systemGray
        })
        #endif
    }
}

#if os(macOS)
extension NSColor {
    convenience init?(hexString: String) {
        let cleaned = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&int) else { return nil }
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        switch cleaned.count {
        case 6:
            r = CGFloat((int >> 16) & 0xFF) / 255
            g = CGFloat((int >> 8) & 0xFF) / 255
            b = CGFloat(int & 0xFF) / 255
        case 3:
            r = CGFloat((int >> 8) & 0xF) * 17 / 255
            g = CGFloat((int >> 4) & 0xF) * 17 / 255
            b = CGFloat(int & 0xF) * 17 / 255
        default:
            return nil
        }
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
#else
extension UIColor {
    convenience init?(hexString: String) {
        let cleaned = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&int) else { return nil }
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        switch cleaned.count {
        case 6:
            r = CGFloat((int >> 16) & 0xFF) / 255
            g = CGFloat((int >> 8) & 0xFF) / 255
            b = CGFloat(int & 0xFF) / 255
        case 3:
            r = CGFloat((int >> 8) & 0xF) * 17 / 255
            g = CGFloat((int >> 4) & 0xF) * 17 / 255
            b = CGFloat(int & 0xF) * 17 / 255
        default:
            return nil
        }
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
#endif

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
// Shared modifiers from the Astra design system.

extension View {

    /// Standard card treatment: surface background, card radius,
    /// hairline border. Replaces cryoCardStyle.
    func astraCardStyle(cornerRadius: CGFloat = Radius.card) -> some View {
        self
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.hairline, lineWidth: 1)
            )
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
