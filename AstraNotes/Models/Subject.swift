//
//  Subject.swift
//  AstraNotes
//
//  IB Subject model with all 6 groups + Core components.
//  SwiftData @Model class - persisted in the shared model container.
//

import Foundation
import SwiftData

// MARK: - IB Subject Groups

enum IBGroup: Int, CaseIterable, Codable, Identifiable {
    case group1 = 1  // Studies in Language & Literature
    case group2 = 2  // Language Acquisition
    case group3 = 3  // Individuals & Societies
    case group4 = 4  // Sciences
    case group5 = 5  // Mathematics
    case group6 = 6  // The Arts

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .group1: return "Studies in Language & Literature"
        case .group2: return "Language Acquisition"
        case .group3: return "Individuals & Societies"
        case .group4: return "Sciences"
        case .group5: return "Mathematics"
        case .group6: return "The Arts"
        }
    }

    var shortName: String {
        switch self {
        case .group1: return "Lang & Lit"
        case .group2: return "Language"
        case .group3: return "Humanities"
        case .group4: return "Sciences"
        case .group5: return "Math"
        case .group6: return "The Arts"
        }
    }

    var astraIcon: AstraIcon {
        switch self {
        case .group1: return .menuBook
        case .group2: return .translate
        case .group3: return .accountBalance
        case .group4: return .science
        case .group5: return .functions
        case .group6: return .palette
        }
    }

    /// Muted semantic color hex per group (roundels, badges).
    var colorHex: String {
        switch self {
        case .group1: return "#B4574E"
        case .group2: return "#2E6BA8"
        case .group3: return "#8A6D2F"
        case .group4: return "#2E7D6E"
        case .group5: return "#5A5CA8"
        case .group6: return "#A04A7D"
        }
    }
}

// MARK: - IB Level

enum IBLevel: String, Codable, CaseIterable {
    case hl = "HL"
    case sl = "SL"

    var displayName: String {
        switch self {
        case .hl: return "Higher Level"
        case .sl: return "Standard Level"
        }
    }

    var shortName: String { rawValue }
}

// MARK: - Subject Model

@Model
final class Subject {
    var id: UUID = UUID()
    var name: String = ""
    var code: String = ""          // e.g., "PHYS", "MATH", "HIST"
    var ibGroup: Int = 4
    var level: String = "HL"
    var teacherName: String = ""
    var room: String = ""
    var colorHex: String = "#2E7D6E"
    var folderName: String = ""   // Obsidian vault folder name
    var createdAt: Date = Date()
    var sortOrder: Int = 0

    // MARK: Relationships
    @Relationship(deleteRule: .cascade) var recordings: [RecordingSession]?

    // MARK: Initialization
    init(
        name: String,
        code: String,
        ibGroup: IBGroup = .group4,
        level: IBLevel = .hl,
        teacherName: String = "",
        colorHex: String = "#2E7D6E"
    ) {
        self.name = name
        self.code = code
        self.ibGroup = ibGroup.rawValue
        self.level = level.rawValue
        self.teacherName = teacherName
        self.colorHex = colorHex
        self.folderName = "\(name) \(level.rawValue)"
    }

    // MARK: Computed

    var group: IBGroup { IBGroup(rawValue: ibGroup) ?? .group4 }
    var ibLevel: IBLevel { IBLevel(rawValue: level) ?? .hl }

    var displayName: String {
        "\(name) \(level)"
    }
}

// MARK: - Subject Color

extension Subject {
    /// Simple hex color wrapper stored on the model.
    struct SubjectColor: Hashable {
        let hex: String

        init(hex: String) {
            self.hex = hex
        }

        static let red    = SubjectColor(hex: "#B4574E")
        static let blue   = SubjectColor(hex: "#2E6BA8")
        static let green  = SubjectColor(hex: "#2E7D6E")
        static let yellow = SubjectColor(hex: "#8A6D2F")
        static let purple = SubjectColor(hex: "#5A5CA8")
        static let orange = SubjectColor(hex: "#A04A7D")
    }

    var color: SubjectColor { .init(hex: colorHex) }
}

// MARK: - Preset IB Subjects

extension Subject {
    /// Common IB subjects pre-configured with correct groups and colors.
    static func presets() -> [Subject] {
        [
            // Group 1: Language & Literature
            Subject(name: "English A", code: "ENGAA1", ibGroup: .group1, level: .hl, colorHex: IBGroup.group1.colorHex),
            Subject(name: "English A", code: "ENGAA2", ibGroup: .group1, level: .sl, colorHex: IBGroup.group1.colorHex),
            // Group 2: Language Acquisition
            Subject(name: "Language B", code: "LANGB", ibGroup: .group2, level: .hl, colorHex: IBGroup.group2.colorHex),
            Subject(name: "Mandarin ab initio", code: "CHNBI", ibGroup: .group2, level: .sl, colorHex: IBGroup.group2.colorHex),
            // Group 3: Humanities
            Subject(name: "History", code: "HIST", ibGroup: .group3, level: .hl, colorHex: IBGroup.group3.colorHex),
            Subject(name: "Economics", code: "ECON", ibGroup: .group3, level: .hl, colorHex: IBGroup.group3.colorHex),
            Subject(name: "Psychology", code: "PSYCH", ibGroup: .group3, level: .sl, colorHex: IBGroup.group3.colorHex),
            // Group 4: Sciences
            Subject(name: "Physics", code: "PHYS", ibGroup: .group4, level: .hl, colorHex: IBGroup.group4.colorHex),
            Subject(name: "Chemistry", code: "CHEM", ibGroup: .group4, level: .hl, colorHex: IBGroup.group4.colorHex),
            Subject(name: "Biology", code: "BIO", ibGroup: .group4, level: .hl, colorHex: IBGroup.group4.colorHex),
            Subject(name: "Computer Science", code: "COSC", ibGroup: .group4, level: .hl, colorHex: IBGroup.group4.colorHex),
            Subject(name: "Environmental Systems", code: "ESS", ibGroup: .group4, level: .sl, colorHex: IBGroup.group4.colorHex),
            // Group 5: Mathematics
            Subject(name: "Analysis & Approaches", code: "AA", ibGroup: .group5, level: .hl, colorHex: IBGroup.group5.colorHex),
            Subject(name: "Applications & Interpretation", code: "AI", ibGroup: .group5, level: .sl, colorHex: IBGroup.group5.colorHex),
            // Group 6: Arts
            Subject(name: "Visual Arts", code: "VART", ibGroup: .group6, level: .hl, colorHex: IBGroup.group6.colorHex),
            Subject(name: "Music", code: "MUSIC", ibGroup: .group6, level: .sl, colorHex: IBGroup.group6.colorHex),
        ]
    }
}
