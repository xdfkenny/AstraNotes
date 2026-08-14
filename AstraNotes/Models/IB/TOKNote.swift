import SwiftUI
import SwiftData

@Model
final class TOKNote {
    var id: UUID
    var title: String
    var content: String // Markdown
    var knowledgeQuestion: String
    var waysOfKnowing: [String] // e.g., ["Reason", "Emotion", "Perception"]
    var areasOfKnowledge: [String] // e.g., ["Natural Sciences", "Ethics"]
    var realWorldSituation: String?
    var prescribedTitle: String?
    var exhibitionObject: String?
    var dateCreated: Date
    var lastEdited: Date
    var tags: [String]
    var relatedNoteIDs: [UUID]

    // All WOKs
    static let allWOKs = [
        "Language", "Sense Perception", "Emotion", "Reason",
        "Imagination", "Faith", "Intuition", "Memory"
    ]
    // All AOKs
    static let allAOKs = [
        "Natural Sciences", "Human Sciences", "History", "The Arts",
        "Ethics", "Religious Knowledge Systems", "Indigenous Knowledge Systems", "Mathematics"
    ]

    init(
        title: String = "TOK Reflection",
        content: String = "",
        knowledgeQuestion: String = "",
        waysOfKnowing: [String] = [],
        areasOfKnowledge: [String] = [],
        realWorldSituation: String? = nil,
        prescribedTitle: String? = nil,
        exhibitionObject: String? = nil,
        dateCreated: Date = .now,
        lastEdited: Date = .now,
        tags: [String] = [],
        relatedNoteIDs: [UUID] = []
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.knowledgeQuestion = knowledgeQuestion
        self.waysOfKnowing = waysOfKnowing
        self.areasOfKnowledge = areasOfKnowledge
        self.realWorldSituation = realWorldSituation
        self.prescribedTitle = prescribedTitle
        self.exhibitionObject = exhibitionObject
        self.dateCreated = dateCreated
        self.lastEdited = lastEdited
        self.tags = tags
        self.relatedNoteIDs = relatedNoteIDs
    }
}
