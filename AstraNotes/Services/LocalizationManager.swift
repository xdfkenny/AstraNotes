import SwiftUI

// MARK: - Localization Manager
// Manages the app's display language at runtime. Supports 13 languages.
// Uses Apple's AppleLanguages UserDefaults override for full localization.

@Observable
final class LocalizationManager {

    // MARK: - Singleton
    nonisolated(unsafe) static let shared = LocalizationManager()

    // MARK: - Supported Languages
    static let supportedAppLanguages: [(code: String, name: String)] = [
        ("en", "English"),
        ("es", "Español"),
        ("zh-Hans", "中文 (简体)"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("ja", "日本語"),
        ("ko", "한국어"),
        ("pt", "Português"),
        ("ar", "العربية"),
        ("hi", "हिन्दी"),
        ("ru", "Русский"),
        ("it", "Italiano"),
        ("nl", "Nederlands"),
    ]

    // MARK: - Current Language
    var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "appLanguage")
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
        }
    }

    // MARK: - Initialization
    init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        self.currentLanguage = saved
        // Ensure AppleLanguages is set
        UserDefaults.standard.set([saved], forKey: "AppleLanguages")
    }

    // MARK: - Public Methods
    func setLanguage(_ code: String) {
        currentLanguage = code
    }

    /// The display name for the current language.
    var currentLanguageDisplayName: String {
        Self.supportedAppLanguages.first(where: { $0.code == currentLanguage })?.name ?? currentLanguage
    }

    /// Returns the native name for a given language code.
    static func displayName(for code: String) -> String {
        supportedAppLanguages.first(where: { $0.code == code })?.name ?? code
    }
}

// MARK: - Environment Key
private struct LocalizationManagerKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    var localizationManager: LocalizationManager {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
}
