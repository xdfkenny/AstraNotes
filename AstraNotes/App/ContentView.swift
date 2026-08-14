import SwiftUI
import SwiftData

// MARK: - Navigation Destination
// Enumerates every top-level section in the app. Each case carries
// a human-readable display name and an SF Symbol icon for the sidebar.

enum NavigationDestination: String, CaseIterable, Identifiable {
    case dashboard
    case recording
    case transcription
    case notes
    case flashcards
    case quiz
    case studyGuide
    case tok
    case ee
    case ia
    case cas
    case settings

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dashboard:     return String(localized: "nav.dashboard")
        case .recording:     return String(localized: "nav.recording")
        case .transcription: return String(localized: "nav.transcription")
        case .notes:         return String(localized: "nav.notes")
        case .flashcards:    return String(localized: "nav.flashcards")
        case .quiz:          return String(localized: "nav.quiz")
        case .studyGuide:    return String(localized: "nav.studyGuide")
        case .tok:           return String(localized: "nav.tok")
        case .ee:            return String(localized: "nav.extendedEssay")
        case .ia:            return String(localized: "nav.internalAssessment")
        case .cas:           return String(localized: "nav.cas")
        case .settings:      return String(localized: "nav.settings")
        }
    }

    var icon: String {
        switch self {
        case .dashboard:     return "square.grid.2x2"
        case .recording:     return "mic.circle"
        case .transcription: return "text.document"
        case .notes:         return "doc.text"
        case .flashcards:    return "square.stack"
        case .quiz:          return "questionmark.circle"
        case .studyGuide:    return "book"
        case .tok:           return "brain"
        case .ee:            return "graduationcap"
        case .ia:            return "chart.bar"
        case .cas:           return "heart.circle"
        case .settings:      return "gearshape"
        }
    }
}

// MARK: - Content View
// Root view that provides a NavigationSplitView with a sidebar on the
// left and a detail area on the right. The detail area switches between
// views based on the currently selected NavigationDestination.

struct ContentView: View {
    @Environment(\.themeManager) private var themeManager
    @State private var selectedDestination: NavigationDestination = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedDestination: $selectedDestination)
                .navigationTitle(String(localized: "app.name"))
                .background(CryoColors.backgroundWarm(themeManager))
        } detail: {
            ZStack {
                // Base background
                CryoColors.background(themeManager)
                    .ignoresSafeArea()

                // Subtle frost noise overlay for the cryo aesthetic
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.03)
                    .ignoresSafeArea()

                detailContent
            }
        }
    }

    // MARK: - Detail Content Switcher
    @ViewBuilder
    private var detailContent: some View {
        switch selectedDestination {
        case .dashboard:
            DashboardView()
        case .recording:
            RecordingView()
        case .transcription:
            TranscriptionView()
        case .notes:
            NoteDetailView()
        case .flashcards:
            FlashcardReviewView()
        case .quiz:
            QuizView()
        case .studyGuide:
            StudyGuideView()
        case .tok:
            TOKPlannerView()
        case .ee:
            EETrackerView()
        case .ia:
            IAWorkbenchView()
        case .cas:
            CASJournalView()
        case .settings:
            SettingsView()
        }
    }
}
