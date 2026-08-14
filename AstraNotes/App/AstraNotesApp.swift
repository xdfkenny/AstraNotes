import SwiftUI
import SwiftData

// MARK: - AstraNotes App Entry Point
// Main application entry point for AstraNotes - an IB study companion.
// Persists models via SwiftData, manages theme and localization.

@main
struct AstraNotesApp: App {

    // MARK: - Font Registration
    // Registers the bundled Google Material Symbols font for AstraIconView.
    init() {
        FontRegistrar.register()
    }

    // MARK: - Theme Manager
    // Persistent theme state managed through @Observable and UserDefaults.
    @State private var themeManager = ThemeManager()

    // MARK: - Localization Manager
    // Manages app display language at runtime.
    @State private var localizationManager = LocalizationManager.shared

    // MARK: - Shared Model Container
    // SwiftData container that persists all application models.
    // Stored on disk in the app's default container directory.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RecordingSession.self,
            TranscriptionResult.self,
            GeneratedNote.self,
            Subject.self,
            Flashcard.self,
            QuizQuestion.self,
            AppSettings.self,
            TOKNote.self,
            ExtendedEssay.self,
            InternalAssessment.self,
            CASEntry.self
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Scene Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeManager)
                .environment(localizationManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .defaultSize(width: 1200, height: 800)
        #endif
    }
}
