import SwiftUI
import SwiftData

@Model
final class CASEntry {
    var id: UUID
    var title: String
    var activityDescription: String
    var casCategory: CASCategory // Creativity, Activity, Service

    // Activity details
    var startDate: Date
    var endDate: Date?
    var hoursSpent: Double
    var isOngoing: Bool

    // Learning outcomes (7 outcomes)
    var achievedOutcomes: [String] // Set of outcome identifiers
    static let allOutcomes: [CASOutcome] = [
        CASOutcome(id: "identify_strengths", name: "Identify own strengths", description: "Identify own strengths and areas for growth"),
        CASOutcome(id: "new_challenges", name: "Demonstrate new challenges", description: "Demonstrate that challenges have been undertaken, developing new skills"),
        CASOutcome(id: "plan_initiate", name: "Plan and initiate", description: "Plan and initiate a CAS experience"),
        CASOutcome(id: "show_perseverance", name: "Show perseverance", description: "Show perseverance and commitment in CAS experiences"),
        CASOutcome(id: "work_collaboratively", name: "Work collaboratively", description: "Demonstrate the skills and recognize the benefits of working collaboratively"),
        CASOutcome(id: "engage_issues", name: "Engage with issues", description: "Engage with issues of global significance"),
        CASOutcome(id: "recognize_ethics", name: "Recognize ethics", description: "Recognize and consider the ethics of choices and actions")
    ]

    // Reflection
    var reflections: [CASReflection]
    var evidence: [String] // File paths or URLs

    // Supervisor
    var supervisor: String?
    var supervisorApproved: Bool

    var status: CASStatus
    var tags: [String]

    // Hours by category
    var creativityHours: Double
    var activityHours: Double
    var serviceHours: Double

    init(
        title: String = "CAS Activity",
        description: String = "",
        casCategory: CASCategory = .creativity,
        startDate: Date = .now,
        endDate: Date? = nil,
        hoursSpent: Double = 0,
        isOngoing: Bool = false,
        achievedOutcomes: [String] = [],
        reflections: [CASReflection] = [],
        evidence: [String] = [],
        supervisor: String? = nil,
        supervisorApproved: Bool = false,
        status: CASStatus = .planned,
        tags: [String] = [],
        creativityHours: Double = 0,
        activityHours: Double = 0,
        serviceHours: Double = 0
    ) {
        self.id = UUID()
        self.title = title
        self.activityDescription = description
        self.casCategory = casCategory
        self.startDate = startDate
        self.endDate = endDate
        self.hoursSpent = hoursSpent
        self.isOngoing = isOngoing
        self.achievedOutcomes = achievedOutcomes
        self.reflections = reflections
        self.evidence = evidence
        self.supervisor = supervisor
        self.supervisorApproved = supervisorApproved
        self.status = status
        self.tags = tags
        self.creativityHours = creativityHours
        self.activityHours = activityHours
        self.serviceHours = serviceHours
    }
}

struct CASOutcome: Identifiable {
    var id: String
    var name: String
    var description: String
}

struct CASReflection: Codable, Identifiable {
    var id: UUID
    var date: Date
    var content: String
    var linkedOutcomes: [String]

    init(
        id: UUID = UUID(),
        date: Date = .now,
        content: String = "",
        linkedOutcomes: [String] = []
    ) {
        self.id = id
        self.date = date
        self.content = content
        self.linkedOutcomes = linkedOutcomes
    }
}

enum CASCategory: String, Codable, CaseIterable {
    case creativity = "Creativity"
    case activity = "Activity"
    case service = "Service"

    var astraIcon: AstraIcon {
        switch self {
        case .creativity: return .brush
        case .activity: return .directionsRun
        case .service: return .favorite
        }
    }

    var color: String {
        switch self {
        case .creativity: return "#A8D8EA"
        case .activity: return "#7EC8E3"
        case .service: return "#E8D5E0"
        }
    }
}

enum CASStatus: String, Codable, CaseIterable {
    case planned = "planned"
    case inProgress = "in_progress"
    case completed = "completed"
    case needsReview = "needs_review"

    var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .needsReview: return "Needs Review"
        }
    }
}
