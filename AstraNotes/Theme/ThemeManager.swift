import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Theme Mode
// Represents the three appearance modes the user can choose from:
// light, dark, or follow the system setting.

enum ThemeMode: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light:  return "Light"
        case .dark:   return "Dark"
        case .system: return "System"
        }
    }

    var astraIcon: AstraIcon {
        switch self {
        case .light:  return .lightMode
        case .dark:   return .darkMode
        case .system: return .contrast
        }
    }
}

// MARK: - Theme Manager
// Centralized, observable theme manager. Uses the @Observable macro so
// that any SwiftUI view that reads its properties will re-render
// automatically. The chosen mode is persisted via UserDefaults so it
// survives app launches.

@Observable
final class ThemeManager {

    // MARK: - Stored Properties

    /// The current appearance mode. Setting this also persists the value.
    var mode: ThemeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "themeMode")
        }
    }

    // MARK: - Initialization

    init() {
        let saved = UserDefaults.standard.string(forKey: "themeMode") ?? ThemeMode.system.rawValue
        self.mode = ThemeMode(rawValue: saved) ?? .system
    }

    // MARK: - Computed Properties

    /// The SwiftUI `ColorScheme` that corresponds to the current mode.
    /// Returns `nil` for `.system` so SwiftUI handles it automatically.
    var colorScheme: ColorScheme? {
        switch mode {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    /// Whether the effective appearance is dark. For `.system` this queries
    /// `NSApp.effectiveAppearance` to detect the current OS setting.
    var isDark: Bool {
        switch mode {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            #if os(macOS)
            return NSApp.effectiveAppearance.bestMatch(
                from: [.darkAqua, .aqua]
            ) == .darkAqua
            #else
            return UITraitCollection.current.userInterfaceStyle == .dark
            #endif
        }
    }
}

// MARK: - Environment Key
// Custom environment key so any view can access the ThemeManager via
// `@Environment(\.themeManager)`.

private struct ThemeManagerKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}
