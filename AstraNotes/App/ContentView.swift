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

    var astraIcon: AstraIcon {
        switch self {
        case .dashboard:     return .gridView
        case .recording:     return .mic
        case .transcription: return .description
        case .notes:         return .description
        case .flashcards:    return .style
        case .quiz:          return .help
        case .studyGuide:    return .menuBook
        case .tok:           return .psychology
        case .ee:            return .school
        case .ia:            return .barChart
        case .cas:           return .favorite
        case .settings:      return .settings
        }
    }
}

// MARK: - Content View
// Root view with NavigationSplitView: sidebar on the left, detail on the
// right. The detail area switches based on the selected destination.

struct ContentView: View {
    @Environment(\.themeManager) private var themeManager
    @State private var selectedDestination: NavigationDestination = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedDestination: $selectedDestination)
                .navigationTitle(String(localized: "app.name"))
                .background(Color.surfaceBackground)
        } detail: {
            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.surfaceBackground)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            selectedDestination = .settings
                        } label: {
                            AstraIconView(.settings, size: 14)
                        }
                        .help(String(localized: "nav.settings"))
                    }
                }
        }
    }

    // MARK: - Detail Content Switcher
    @ViewBuilder
    private var detailContent: some View {
        switch selectedDestination {
        case .dashboard:
            DashboardView(onNavigate: { selectedDestination = $0 })
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
