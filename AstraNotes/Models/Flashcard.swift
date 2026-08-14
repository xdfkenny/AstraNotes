import SwiftUI
import SwiftData

@Model
final class Flashcard {
    var id: UUID
    var deckName: String
    var subjectName: String?
    var frontContent: String
    var backContent: String
    var contextHint: String? // Extra context for the card
    var bloomLevel: BloomLevel // Taxonomy level
    var tags: [String]

    // SM-2 Spaced Repetition
    var interval: Double // Days until next review
    var repetitions: Int // Number of successful repetitions
    var easeFactor: Double // Easiness factor (default 2.5)
    var nextReviewDate: Date
    var lastReviewDate: Date?
    var reviewCount: Int // Total reviews
    var correctCount: Int // Correct answers

    var isDue: Bool {
        nextReviewDate <= .now
    }

    var accuracy: Double {
        guard reviewCount > 0 else { return 0 }
        return Double(correctCount) / Double(reviewCount)
    }

    init(
        deckName: String = "Default",
        subjectName: String? = nil,
        frontContent: String = "",
        backContent: String = "",
        contextHint: String? = nil,
        bloomLevel: BloomLevel = .remember,
        tags: [String] = [],
        interval: Double = 1,
        repetitions: Int = 0,
        easeFactor: Double = 2.5,
        nextReviewDate: Date = .now,
        reviewCount: Int = 0,
        correctCount: Int = 0
    ) {
        self.id = UUID()
        self.deckName = deckName
        self.subjectName = subjectName
        self.frontContent = frontContent
        self.backContent = backContent
        self.contextHint = contextHint
        self.bloomLevel = bloomLevel
        self.tags = tags
        self.interval = interval
        self.repetitions = repetitions
        self.easeFactor = easeFactor
        self.nextReviewDate = nextReviewDate
        self.lastReviewDate = nil
        self.reviewCount = reviewCount
        self.correctCount = correctCount
    }

    // SM-2 Algorithm
    func updateAfterReview(quality: Int) -> FlashcardUpdateResult {
        let ef = computeNewEaseFactor(current: easeFactor, quality: quality)
        let (newInterval, newReps) = computeNewIntervalAndRepetitions(
            currentInterval: interval,
            currentRepetitions: repetitions,
            newEaseFactor: ef,
            quality: quality
        )
        let nextDate = Calendar.current.date(
            byAdding: .day,
            value: Int(newInterval),
            to: Date()
        ) ?? Date()
        return FlashcardUpdateResult(
            easeFactor: ef,
            interval: newInterval,
            repetitions: newReps,
            nextReviewDate: nextDate
        )
    }
}

// MARK: - SM-2 Helper Functions (extracted to avoid type-checker timeouts)

private func computeNewEaseFactor(current: Double, quality: Int) -> Double {
    let q = Double(5 - quality)
    let adjustment = 0.1 - q * (0.08 + q * 0.02)
    return max(1.3, current + adjustment)
}

private func computeNewIntervalAndRepetitions(
    currentInterval: Double,
    currentRepetitions: Int,
    newEaseFactor: Double,
    quality: Int
) -> (interval: Double, repetitions: Int) {
    guard quality >= 3 else {
        return (1, 0)
    }
    let newReps = currentRepetitions + 1
    let newInterval: Double
    if currentRepetitions == 0 {
        newInterval = 1
    } else if currentRepetitions == 1 {
        newInterval = 6
    } else {
        newInterval = currentInterval * newEaseFactor
    }
    return (newInterval, newReps)
}

struct FlashcardUpdateResult {
    var easeFactor: Double
    var interval: Double
    var repetitions: Int
    var nextReviewDate: Date
}

enum BloomLevel: String, Codable, CaseIterable {
    case remember = "Remember"
    case understand = "Understand"
    case apply = "Apply"
    case analyze = "Analyze"
    case evaluate = "Evaluate"
    case create = "Create"

    var level: Int {
        switch self {
        case .remember: return 1
        case .understand: return 2
        case .apply: return 3
        case .analyze: return 4
        case .evaluate: return 5
        case .create: return 6
        }
    }

    var color: String {
        switch self {
        case .remember: return "#7EC8E3"
        case .understand: return "#A8D8EA"
        case .apply: return "#B8E3F5"
        case .analyze: return "#4A9ECF"
        case .evaluate: return "#E8D5E0"
        case .create: return "#C4A8B8"
        }
    }
}
