import SwiftUI
import SwiftData

@Model
final class ExtendedEssay {
    var id: UUID
    var title: String
    var subject: String
    var researchQuestion: String
    var content: String // Full essay markdown
    var wordCount: Int
    var maxWordCount: Int // 4000
    var supervisor: String?
    var session: String // e.g., "2026"

    // RPPF reflections
    var rppfInitial: String? // First reflection
    var rppfMidterm: String? // Interim reflection
    var rppfFinal: String? // Final reflection (viva voce)

    // Meeting notes
    var meetingNotes: [MeetingNote]

    // Progress tracking
    var status: EEStatus
    var dateStarted: Date
    var dateDeadline: Date?
    var dateSubmitted: Date?
    var tags: [String]
    var relatedNoteIDs: [UUID]

    var progress: Double {
        let components: [Bool] = [
            !researchQuestion.isEmpty,
            !content.isEmpty,
            rppfInitial != nil,
            rppfMidterm != nil,
            rppfFinal != nil
        ]
        return Double(components.filter { $0 }.count) / Double(components.count)
    }

    init(
        title: String = "Extended Essay",
        subject: String = "",
        researchQuestion: String = "",
        content: String = "",
        wordCount: Int = 0,
        maxWordCount: Int = 4000,
        supervisor: String? = nil,
        session: String = "2026",
        rppfInitial: String? = nil,
        rppfMidterm: String? = nil,
        rppfFinal: String? = nil,
        meetingNotes: [MeetingNote] = [],
        status: EEStatus = .planning,
        dateStarted: Date = .now,
        dateDeadline: Date? = nil,
        dateSubmitted: Date? = nil,
        tags: [String] = [],
        relatedNoteIDs: [UUID] = []
    ) {
        self.id = UUID()
        self.title = title
        self.subject = subject
        self.researchQuestion = researchQuestion
        self.content = content
        self.wordCount = wordCount
        self.maxWordCount = maxWordCount
        self.supervisor = supervisor
        self.session = session
        self.rppfInitial = rppfInitial
        self.rppfMidterm = rppfMidterm
        self.rppfFinal = rppfFinal
        self.meetingNotes = meetingNotes
        self.status = status
        self.dateStarted = dateStarted
        self.dateDeadline = dateDeadline
        self.dateSubmitted = dateSubmitted
        self.tags = tags
        self.relatedNoteIDs = relatedNoteIDs
    }
}

enum EEStatus: String, Codable, CaseIterable {
    case planning = "planning"
    case researching = "researching"
    case drafting = "drafting"
    case reviewing = "reviewing"
    case submitted = "submitted"

    var displayName: String {
        switch self {
        case .planning: return "Planning"
        case .researching: return "Researching"
        case .drafting: return "Drafting"
        case .reviewing: return "Reviewing"
        case .submitted: return "Submitted"
        }
    }

    var icon: String {
        switch self {
        case .planning: return "lightbulb"
        case .researching: return "magnifyingglass"
        case .drafting: return "pencil"
        case .reviewing: return "eye"
        case .submitted: return "checkmark.circle"
        }
    }
}

struct MeetingNote: Codable, Identifiable {
    var id: UUID
    var date: Date
    var summary: String
    var actionItems: [String]

    init(
        id: UUID = UUID(),
        date: Date = .now,
        summary: String = "",
        actionItems: [String] = []
    ) {
        self.id = id
        self.date = date
        self.summary = summary
        self.actionItems = actionItems
    }
}
