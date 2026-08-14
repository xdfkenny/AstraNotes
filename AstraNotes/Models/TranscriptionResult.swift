import SwiftUI
import SwiftData

@Model
final class TranscriptionResult {
    var id: UUID
    var recordingSessionID: UUID?
    var fullText: String
    var segments: [TranscriptionSegment] // stored as JSON or separate model
    var language: String // "en", "es", "zh", "auto"
    var confidence: Double // 0-1
    var dateTranscribed: Date
    var wordCount: Int
    var isEdited: Bool
    var editedText: String?

    init(
        recordingSessionID: UUID? = nil,
        fullText: String = "",
        segments: [TranscriptionSegment] = [],
        language: String = "auto",
        confidence: Double = 0.0,
        dateTranscribed: Date = .now,
        wordCount: Int = 0,
        isEdited: Bool = false,
        editedText: String? = nil
    ) {
        self.id = UUID()
        self.recordingSessionID = recordingSessionID
        self.fullText = fullText
        self.segments = segments
        self.language = language
        self.confidence = confidence
        self.dateTranscribed = dateTranscribed
        self.wordCount = wordCount
        self.isEdited = isEdited
        self.editedText = editedText
    }

    var displayText: String {
        isEdited ? (editedText ?? fullText) : fullText
    }

    var languageDisplayName: String {
        switch language {
        case "en": return "English"
        case "es": return "Spanish"
        case "zh": return "Chinese"
        default: return "Auto-detected"
        }
    }
}

// MARK: - Transcription Segment
struct TranscriptionSegment: Codable, Identifiable, Hashable {
    var id: UUID
    var speakerID: Int?
    var text: String
    var startTime: Double
    var endTime: Double
    var confidence: Double
    var words: [WordTimestamp]

    init(
        id: UUID = UUID(),
        speakerID: Int? = nil,
        text: String = "",
        startTime: Double = 0,
        endTime: Double = 0,
        confidence: Double = 1.0,
        words: [WordTimestamp] = []
    ) {
        self.id = id
        self.speakerID = speakerID
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.confidence = confidence
        self.words = words
    }

    var formattedTimeRange: String {
        String(format: "%.1f - %.1f", startTime, endTime)
    }

    var duration: Double {
        endTime - startTime
    }
}

struct WordTimestamp: Codable, Identifiable, Hashable {
    var id: UUID
    var word: String
    var startTime: Double
    var endTime: Double
    var confidence: Double

    init(
        id: UUID = UUID(),
        word: String = "",
        startTime: Double = 0,
        endTime: Double = 0,
        confidence: Double = 1.0
    ) {
        self.id = id
        self.word = word
        self.startTime = startTime
        self.endTime = endTime
        self.confidence = confidence
    }
}
