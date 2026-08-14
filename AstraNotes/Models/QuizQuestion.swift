import SwiftUI
import SwiftData

@Model
final class QuizQuestion {
    var id: UUID
    var subjectName: String?
    var topic: String
    var type: QuestionType
    var difficulty: QuestionDifficulty
    var content: String // The question text
    var options: [String] // For multiple choice
    var correctAnswer: String
    var markingScheme: String? // For essay/short answer
    var maxMarks: Int
    var tags: [String]
    var explanation: String?
    var sourceNoteID: UUID?

    // User performance
    var timesAnswered: Int
    var timesCorrect: Int

    var accuracy: Double {
        guard timesAnswered > 0 else { return 0 }
        return Double(timesCorrect) / Double(timesAnswered)
    }

    init(
        subjectName: String? = nil,
        topic: String = "",
        type: QuestionType = .multipleChoice,
        difficulty: QuestionDifficulty = .sl,
        content: String = "",
        options: [String] = [],
        correctAnswer: String = "",
        markingScheme: String? = nil,
        maxMarks: Int = 1,
        tags: [String] = [],
        explanation: String? = nil,
        sourceNoteID: UUID? = nil
    ) {
        self.id = UUID()
        self.subjectName = subjectName
        self.topic = topic
        self.type = type
        self.difficulty = difficulty
        self.content = content
        self.options = options
        self.correctAnswer = correctAnswer
        self.markingScheme = markingScheme
        self.maxMarks = maxMarks
        self.tags = tags
        self.explanation = explanation
        self.sourceNoteID = sourceNoteID
        self.timesAnswered = 0
        self.timesCorrect = 0
    }
}

enum QuestionType: String, Codable, CaseIterable {
    case multipleChoice = "multiple_choice"
    case shortAnswer = "short_answer"
    case essay = "essay"
    case dataResponse = "data_response"
    case extendedResponse = "extended_response"

    var displayName: String {
        switch self {
        case .multipleChoice: return "Multiple Choice"
        case .shortAnswer: return "Short Answer"
        case .essay: return "Essay"
        case .dataResponse: return "Data Response"
        case .extendedResponse: return "Extended Response"
        }
    }

    var paperStyle: String {
        switch self {
        case .multipleChoice: return "Paper 1"
        case .shortAnswer, .dataResponse: return "Paper 2"
        case .essay, .extendedResponse: return "Paper 2/3"
        }
    }
}

enum QuestionDifficulty: String, Codable, CaseIterable {
    case sl = "SL"
    case hl = "HL"
    case mixed = "Mixed"
}
