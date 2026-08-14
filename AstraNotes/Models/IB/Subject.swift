import SwiftUI
import SwiftData
import Foundation

// MARK: - Subject Group
// Represents the six IB subject groups plus the core (TOK, CAS, EE).

enum SubjectGroup: String, CaseIterable, Codable, Identifiable {
    case studiesInLanguageAndLiterature = "group1"   // Group 1
    case languageAcquisition            = "group2"   // Group 2
    case individualsAndSocieties         = "group3"   // Group 3
    case sciences                        = "group4"   // Group 4
    case mathematics                     = "group5"   // Group 5
    case theArts                         = "group6"   // Group 6
    case core                            = "core"     // Core: TOK, CAS, EE

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .studiesInLanguageAndLiterature: return "Studies in Language & Literature"
        case .languageAcquisition:            return "Language Acquisition"
        case .individualsAndSocieties:         return "Individuals & Societies"
        case .sciences:                        return "Sciences"
        case .mathematics:                     return "Mathematics"
        case .theArts:                         return "The Arts"
        case .core:                            return "Core"
        }
    }

    var shortName: String {
        switch self {
        case .studiesInLanguageAndLiterature: return "Lang & Lit"
        case .languageAcquisition:            return "Lang Acq."
        case .individualsAndSocieties:         return "Ind. & Soc."
        case .sciences:                        return "Sciences"
        case .mathematics:                     return "Math"
        case .theArts:                         return "Arts"
        case .core:                            return "Core"
        }
    }

    /// The group number for display (1-6), or 0 for Core.
    var groupNumber: Int {
        switch self {
        case .studiesInLanguageAndLiterature: return 1
        case .languageAcquisition:            return 2
        case .individualsAndSocieties:         return 3
        case .sciences:                        return 4
        case .mathematics:                     return 5
        case .theArts:                         return 6
        case .core:                            return 0
        }
    }

    var icon: String {
        switch self {
        case .studiesInLanguageAndLiterature: return "text.book.closed"
        case .languageAcquisition:            return "globe"
        case .individualsAndSocieties:         return "person.2"
        case .sciences:                        return "atom"
        case .mathematics:                     return "function"
        case .theArts:                         return "paintpalette"
        case .core:                            return "star.circle"
        }
    }
}

// MARK: - IB Level
// The two course levels in the IB Diploma Programme.

enum IBLevel: String, CaseIterable, Codable, Identifiable {
    case hl = "HL"
    case sl = "SL"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hl: return "Higher Level"
        case .sl: return "Standard Level"
        }
    }

    var shortName: String {
        return rawValue
    }

    /// Typical maximum hours for this level.
    var teachingHours: Int {
        switch self {
        case .hl: return 240
        case .sl: return 150
        }
    }
}

// MARK: - Subject Model
// SwiftData model representing an IB subject a student is enrolled in.
// Tracks the subject name, group, level, teacher, room, and a
// user-customizable accent color.

@Model
final class Subject {

    // MARK: - Properties

    /// Unique identifier for this subject.
    var id: UUID

    /// The full name of the subject, e.g. "Biology HL".
    var name: String

    /// Which IB group this subject belongs to.
    var group: SubjectGroup

    /// Whether the student is taking Higher or Standard Level.
    var level: IBLevel

    /// The teacher's name (optional).
    var teacher: String

    /// The classroom / room number (optional).
    var room: String

    /// A hex color string used as this subject's accent color in the UI.
    var colorHex: String

    /// Notes or additional info about the subject.
    var notes: String

    /// Whether this subject is currently active / in the student's schedule.
    var isActive: Bool

    /// The sort order for display in lists.
    var sortOrder: Int

    /// Date when this subject was first added.
    var createdAt: Date

    /// Date when the subject was last modified.
    var updatedAt: Date

    // MARK: - Relationships

    /// All generated notes associated with this subject.
    @Relationship(deleteRule: .cascade)
    var generatedNotes: [GeneratedNote]?

    /// All flashcards tagged to this subject.
    @Relationship(deleteRule: .cascade)
    var flashcards: [Flashcard]?

    /// All quiz questions tagged to this subject.
    @Relationship(deleteRule: .cascade)
    var quizQuestions: [QuizQuestion]?

    // MARK: - Initialization

    init(
        name: String = "",
        group: SubjectGroup = .sciences,
        level: IBLevel = .hl,
        teacher: String = "",
        room: String = "",
        colorHex: String = "#7EC8E3",
        notes: String = "",
        isActive: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.group = group
        self.level = level
        self.teacher = teacher
        self.room = room
        self.colorHex = colorHex
        self.notes = notes
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Subject Computed Helpers

extension Subject {

    /// A convenience computed property that returns the subject color
    /// as a SwiftUI Color using the hex initializer from Extensions.swift.
    var color: Color {
        Color(hex: colorHex)
    }

    /// Full display name including level, e.g. "Biology HL".
    var displayName: String {
        if name.isEmpty {
            return "Untitled Subject"
        }
        return name
    }

    /// Display string with group, e.g. "Biology HL (Sciences)".
    var detailedDescription: String {
        "\(displayName) (\(group.shortName))"
    }
}

// MARK: - Subject Predicates
// Common #Predicate patterns for querying subjects.

extension Subject {

    /// Returns a predicate that filters for active subjects.
    @available(macOS 14.0, *)
    static var isActivePredicate: Predicate<Subject> {
        #Predicate { $0.isActive == true }
    }

    /// Returns a predicate that filters subjects by name containing the
    /// given search text.
    @available(macOS 14.0, *)
    static func nameContains(_ searchText: String) -> Predicate<Subject> {
        #Predicate { subject in
            searchText.isEmpty ||
            subject.name.localizedStandardContains(searchText)
        }
    }

    /// Returns a predicate for subjects in a specific group.
    @available(macOS 14.0, *)
    static func inGroup(_ group: SubjectGroup) -> Predicate<Subject> {
        #Predicate { subject in
            subject.group == group
        }
    }
}

// MARK: - Sample Data

extension Subject {

    /// Returns an array of example subjects for preview and testing purposes.
    static var sampleSubjects: [Subject] {
        [
            Subject(name: "English A: Literature", group: .studiesInLanguageAndLiterature, level: .hl, teacher: "Ms. Carter", room: "B12", colorHex: "#7EC8E3"),
            Subject(name: "French B", group: .languageAcquisition, level: .sl, teacher: "M. Dupont", room: "C5", colorHex: "#A8D8EA"),
            Subject(name: "History", group: .individualsAndSocieties, level: .hl, teacher: "Mr. Thompson", room: "A8", colorHex: "#B8E3F5"),
            Subject(name: "Biology", group: .sciences, level: .hl, teacher: "Dr. Patel", room: "Lab 3", colorHex: "#4A9ECF"),
            Subject(name: "Mathematics: Analysis & Approaches", group: .mathematics, level: .hl, teacher: "Ms. Kim", room: "D10", colorHex: "#5DB8E0"),
            Subject(name: "Visual Arts", group: .theArts, level: .sl, teacher: "Mr. Rivera", room: "Studio 1", colorHex: "#E8D5E0")
        ]
    }
}
