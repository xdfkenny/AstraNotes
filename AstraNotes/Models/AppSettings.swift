import SwiftUI
import SwiftData

@Model
final class AppSettings {
    var id: UUID
    var deepSeekAPIKey: String
    var obsidianVaultPath: String
    var defaultSubject: String?
    var whisperLanguage: String // "auto", "en", "es", "zh"
    var autoTranscribe: Bool
    var autoGenerateNotes: Bool
    var noteGenerationStyle: String // "detailed", "concise", "exam-focused"
    var flashcardBloomLevel: Int // Default Bloom's level for generated flashcards
    var quizDifficulty: String // "sl", "hl", "mixed"
    var ankiExportEnabled: Bool
    var themeMode: String // "light", "dark", "system"
    var noteOutputLanguage: String // "auto", "en", "es", "zh", "fr", "de", "ja", "ko", "pt", "ar", "hi", "ru", "it"
    var appLanguage: String // "en", "es", "zh-Hans", "fr", "de", "ja", "ko", "pt", "ar", "hi", "ru", "it", "nl"
    var totalTokensUsed: Int
    var totalAPICostEstimate: Double

    init(
        deepSeekAPIKey: String = "",
        obsidianVaultPath: String = "",
        defaultSubject: String? = nil,
        whisperLanguage: String = "auto",
        autoTranscribe: Bool = true,
        autoGenerateNotes: Bool = false,
        noteGenerationStyle: String = "detailed",
        flashcardBloomLevel: Int = 2,
        quizDifficulty: String = "mixed",
        ankiExportEnabled: Bool = false,
        themeMode: String = "system",
        noteOutputLanguage: String = "auto",
        appLanguage: String = "en",
        totalTokensUsed: Int = 0,
        totalAPICostEstimate: Double = 0.0
    ) {
        self.id = UUID()
        self.deepSeekAPIKey = deepSeekAPIKey
        self.obsidianVaultPath = obsidianVaultPath
        self.defaultSubject = defaultSubject
        self.whisperLanguage = whisperLanguage
        self.autoTranscribe = autoTranscribe
        self.autoGenerateNotes = autoGenerateNotes
        self.noteGenerationStyle = noteGenerationStyle
        self.flashcardBloomLevel = flashcardBloomLevel
        self.quizDifficulty = quizDifficulty
        self.ankiExportEnabled = ankiExportEnabled
        self.themeMode = themeMode
        self.noteOutputLanguage = noteOutputLanguage
        self.appLanguage = appLanguage
        self.totalTokensUsed = totalTokensUsed
        self.totalAPICostEstimate = totalAPICostEstimate
    }

    var hasDeepSeekKey: Bool {
        !deepSeekAPIKey.isEmpty
    }

    var hasObsidianVault: Bool {
        !obsidianVaultPath.isEmpty
    }

    var formattedCost: String {
        String(format: "$%.4f", totalAPICostEstimate)
    }

    var formattedTokens: String {
        if totalTokensUsed >= 1_000_000 {
            return String(format: "%.1fM", Double(totalTokensUsed) / 1_000_000)
        } else if totalTokensUsed >= 1_000 {
            return String(format: "%.1fK", Double(totalTokensUsed) / 1_000)
        }
        return "\(totalTokensUsed)"
    }
}
