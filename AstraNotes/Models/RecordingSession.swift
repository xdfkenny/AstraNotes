import SwiftUI
import SwiftData

// MARK: - Transcription Language
// Whisper language selection for recording sessions.

enum TranscriptionLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case chinese = "zh"
    case autoDetect = "auto"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .chinese: return "Chinese"
        case .autoDetect: return "Auto-detect"
        }
    }

    /// Whisper language token (nil for auto).
    var whisperToken: String? {
        switch self {
        case .english: return "en"
        case .spanish: return "es"
        case .chinese: return "zh"
        case .autoDetect: return nil
        }
    }
}

@Model
final class RecordingSession {
    var id: UUID
    var title: String
    var subjectName: String?
    var date: Date
    var duration: TimeInterval // seconds
    var fileName: String?
    var filePath: URL?
    var isImported: Bool
    var notes: String?
    var tags: [String]
    var waveformData: [Float] // normalized 0-1 samples for visualization
    var transcriptionID: UUID?

    init(
        title: String = "Untitled Recording",
        subjectName: String? = nil,
        date: Date = .now,
        duration: TimeInterval = 0,
        fileName: String? = nil,
        filePath: URL? = nil,
        isImported: Bool = false,
        notes: String? = nil,
        tags: [String] = [],
        waveformData: [Float] = [],
        transcriptionID: UUID? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.subjectName = subjectName
        self.date = date
        self.duration = duration
        self.fileName = fileName
        self.filePath = filePath
        self.isImported = isImported
        self.notes = notes
        self.tags = tags
        self.waveformData = waveformData
        self.transcriptionID = transcriptionID
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy HH:mm"
        return formatter.string(from: date)
    }
}
