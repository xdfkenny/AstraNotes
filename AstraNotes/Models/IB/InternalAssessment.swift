import SwiftUI
import SwiftData

@Model
final class InternalAssessment {
    var id: UUID
    var title: String
    var subject: String
    var subjectGroup: Int // 1-6
    var content: String // Full IA markdown
    var wordCount: Int
    var maxWordCount: Int
    var type: IAType

    // Section completion tracking
    var sections: [IASection]

    // Personal engagement
    var explorationReflection: String?
    var analysisReflection: String?
    var evaluationReflection: String?

    var status: IAStatus
    var dateStarted: Date
    var dateDeadline: Date?
    var dateSubmitted: Date?
    var teacher: String?
    var tags: [String]
    var relatedNoteIDs: [UUID]

    var progress: Double {
        let completed = sections.filter { $0.isComplete }.count
        return sections.isEmpty ? 0 : Double(completed) / Double(sections.count)
    }

    init(
        title: String = "Internal Assessment",
        subject: String = "",
        subjectGroup: Int = 4,
        content: String = "",
        wordCount: Int = 0,
        maxWordCount: Int = 2000,
        type: IAType = .scientificExploration,
        sections: [IASection] = [],
        explorationReflection: String? = nil,
        analysisReflection: String? = nil,
        evaluationReflection: String? = nil,
        status: IAStatus = .planning,
        dateStarted: Date = .now,
        dateDeadline: Date? = nil,
        dateSubmitted: Date? = nil,
        teacher: String? = nil,
        tags: [String] = [],
        relatedNoteIDs: [UUID] = []
    ) {
        self.id = UUID()
        self.title = title
        self.subject = subject
        self.subjectGroup = subjectGroup
        self.content = content
        self.wordCount = wordCount
        self.maxWordCount = maxWordCount
        self.type = type
        self.sections = sections
        self.explorationReflection = explorationReflection
        self.analysisReflection = analysisReflection
        self.evaluationReflection = evaluationReflection
        self.status = status
        self.dateStarted = dateStarted
        self.dateDeadline = dateDeadline
        self.dateSubmitted = dateSubmitted
        self.teacher = teacher
        self.tags = tags
        self.relatedNoteIDs = relatedNoteIDs
    }
}

enum IAType: String, Codable, CaseIterable {
    case scientificExploration = "Scientific Exploration"
    case mathematicalExploration = "Mathematical Exploration"
    case historicalInvestigation = "Historical Investigation"
    case writtenTask = "Written Task"
    case oralWork = "Oral Work"
    case fieldwork = "Fieldwork"
    case artwork = "Artwork"
    case other = "Other"

    var displayName: String { rawValue }
}

enum IAStatus: String, Codable, CaseIterable {
    case planning = "planning"
    case inProgress = "in_progress"
    case underReview = "under_review"
    case submitted = "submitted"

    var displayName: String {
        switch self {
        case .planning: return "Planning"
        case .inProgress: return "In Progress"
        case .underReview: return "Under Review"
        case .submitted: return "Submitted"
        }
    }
}

struct IASection: Codable, Identifiable {
    var id: UUID
    var title: String
    var content: String
    var isComplete: Bool
    var order: Int

    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        isComplete: Bool = false,
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.isComplete = isComplete
        self.order = order
    }
}
