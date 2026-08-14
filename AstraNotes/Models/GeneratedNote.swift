import SwiftUI
import SwiftData

@Model
final class GeneratedNote {
    var id: UUID
    var title: String
    var subjectName: String?
    var content: String // Full markdown content
    var transcriptionID: UUID?
    var sourceModel: String // e.g., "DeepSeek V4 Flash"
    var dateGenerated: Date
    var lastEdited: Date
    var isFavorite: Bool
    var tags: [String]
    var type: NoteType
    var obsidianFilePath: String?
    var wordCount: Int
    var tokenCount: Int

    init(
        title: String = "Untitled Note",
        subjectName: String? = nil,
        content: String = "",
        transcriptionID: UUID? = nil,
        sourceModel: String = "DeepSeek V4 Flash",
        dateGenerated: Date = .now,
        lastEdited: Date = .now,
        isFavorite: Bool = false,
        tags: [String] = [],
        type: NoteType = .lecture,
        obsidianFilePath: String? = nil,
        wordCount: Int = 0,
        tokenCount: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.subjectName = subjectName
        self.content = content
        self.transcriptionID = transcriptionID
        self.sourceModel = sourceModel
        self.dateGenerated = dateGenerated
        self.lastEdited = lastEdited
        self.isFavorite = isFavorite
        self.tags = tags
        self.type = type
        self.obsidianFilePath = obsidianFilePath
        self.wordCount = wordCount
        self.tokenCount = tokenCount
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: dateGenerated)
    }
}

enum NoteType: String, Codable, CaseIterable {
    case lecture = "lecture-notes"
    case flashcards = "flashcard-notes"
    case quiz = "quiz-notes"
    case studyGuide = "study-guide"
    case tok = "tok-notes"
    case ee = "ee-notes"
    case ia = "ia-notes"
    case cas = "cas-notes"
    case summary = "summary"

    var displayName: String {
        switch self {
        case .lecture: return "Lecture Notes"
        case .flashcards: return "Flashcard Notes"
        case .quiz: return "Quiz Notes"
        case .studyGuide: return "Study Guide"
        case .tok: return "TOK Notes"
        case .ee: return "EE Notes"
        case .ia: return "IA Notes"
        case .cas: return "CAS Notes"
        case .summary: return "Summary"
        }
    }

    var astraIcon: AstraIcon {
        switch self {
        case .lecture: return .description
        case .flashcards: return .style
        case .quiz: return .help
        case .studyGuide: return .menuBook
        case .tok: return .psychology
        case .ee: return .school
        case .ia: return .barChart
        case .cas: return .favorite
        case .summary: return .checklist
        }
    }
}
