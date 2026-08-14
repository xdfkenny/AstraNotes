// CASJournalView.swift — AstraNotes
// CAS activity journal with the Astra design system.
// Features: statistics dashboard with circular progress indicators,
// activity log with category/status pills, add activity form,
// learning outcomes checklist, reflection area with timeline.

import SwiftUI
import SwiftData

// MARK: - CAS Journal View

struct CASJournalView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var selectedCategory: CASCategoryFilter = .all
    @State private var selectedStatus: CASStatusFilter = .all
    @State private var searchText: String = ""
    @State private var showAddActivity: Bool = false
    @State private var expandedActivityID: UUID?
    @State private var newReflectionText: String = ""
    @State private var showOutcomesPanel: Bool = false

    // New activity form state
    @State private var newTitle: String = ""
    @State private var newDescription: String = ""
    @State private var newCategory: CASCategory = .creativity
    @State private var newSupervisor: String = ""
    @State private var newHours: Double = 0
    @State private var newIsOngoing: Bool = false

    // MARK: - Queries

    @Query private var entries: [CASEntry]

    // MARK: - Computed Properties

    private var filteredEntries: [CASEntry] {
        var result = entries

        switch selectedCategory {
        case .all: break
        case .creativity: result = result.filter { $0.casCategory == .creativity }
        case .activity: result = result.filter { $0.casCategory == .activity }
        case .service: result = result.filter { $0.casCategory == .service }
        }

        switch selectedStatus {
        case .all: break
        case .planned: result = result.filter { $0.status == .planned }
        case .inProgress: result = result.filter { $0.status == .inProgress }
        case .completed: result = result.filter { $0.status == .completed }
        case .needsReview: result = result.filter { $0.status == .needsReview }
        }

        if !searchText.isBlank {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.description.lowercased().contains(query) ||
                $0.supervisor?.lowercased().contains(query) == true ||
                $0.tags.contains { $0.lowercased().contains(query) }
            }
        }

        return result.sorted { $0.startDate > $1.startDate }
    }

    private var totalCreativityHours: Double {
        entries.reduce(0) { $0 + $1.creativityHours }
    }

    private var totalActivityHours: Double {
        entries.reduce(0) { $0 + $1.activityHours }
    }

    private var totalServiceHours: Double {
        entries.reduce(0) { $0 + $1.serviceHours }
    }

    private var totalHours: Double {
        totalCreativityHours + totalActivityHours + totalServiceHours
    }

    private var achievedOutcomeCount: Int {
        var ids = Set<String>()
        for entry in entries {
            for outcomeID in entry.achievedOutcomes {
                ids.insert(outcomeID)
            }
        }
        return ids.count
    }

    private var completedCount: Int {
        entries.filter { $0.status == .completed }.count
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection
                statisticsSection
                filtersSection

                if filteredEntries.isEmpty {
                    emptyState
                } else {
                    activityListSection
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceBackground)
        .sheet(isPresented: $showAddActivity) {
            addActivitySheet
        }
        .sheet(isPresented: $showOutcomesPanel) {
            outcomesChecklistSheet
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("❄️")
                        .font(.system(size: 24))
                    Text(String(localized: "cas.title"))
                        .font(TypeScale.title)
                        .foregroundColor(Color.textPrimary)
                }

                Text(String(localized: "cas.subtitle"))
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    showOutcomesPanel = true
                } label: {
                    HStack(spacing: 6) {
                        AstraIconView(.verified)
                        Text(String(localized: "cas.outcomes"))
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.surface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button {
                    showAddActivity = true
                } label: {
                    HStack(spacing: 6) {
                        AstraIconView(.add)
                        Text(String(localized: "cas.newActivity"))
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.accent, Color.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.accent.opacity(0.15), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        HStack(spacing: 16) {
            // Creativity circle
            circularProgressCard(
                title: String(localized: "cas.creativity"),
                hours: totalCreativityHours,
                goal: 50,
                icon: .brush,
                color: .group6
            )

            // Activity circle
            circularProgressCard(
                title: String(localized: "cas.activity"),
                hours: totalActivityHours,
                goal: 50,
                icon: .directionsRun,
                color: .accent
            )

            // Service circle
            circularProgressCard(
                title: String(localized: "cas.service"),
                hours: totalServiceHours,
                goal: 50,
                icon: .favorite,
                color: .group6.opacity(0.7)
            )

            // Total Activities
            VStack(spacing: 12) {
                Text(entries.count)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color.accent)

                Text(String(localized: "cas.activities"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.06)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .astraCardStyle()

            // Outcomes Achieved
            VStack(spacing: 12) {
                Text("\(achievedOutcomeCount)/7")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color.group6.opacity(0.6))

                Text(String(localized: "cas.outcomes"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.06)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .astraCardStyle()

            // Completed
            VStack(spacing: 12) {
                Text(completedCount)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color.semanticSuccess)

                Text(String(localized: "cas.completed"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.06)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .astraCardStyle()
        }
    }

    // MARK: - Circular Progress Card

    private func circularProgressCard(
        title: String,
        hours: Double,
        goal: Double,
        icon: AstraIcon,
        color: Color
    ) -> some View {
        let progress = min(hours / goal, 1.0)

        return VStack(spacing: 12) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.accentContainer, lineWidth: 6)
                    .frame(width: 80, height: 80)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                // Center text
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", hours))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color.textPrimary)
                    Text(String(localized: "cas.hrs"))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.06)
                }
            }

            HStack(spacing: 4) {
                AstraIconView(icon, size: 11)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .astraCardStyle()
    }

    // MARK: - Filters Section

    private var filtersSection: some View {
        VStack(spacing: 16) {
            // Category filter pills
            HStack(spacing: 8) {
                Text(String(localized: "cas.category"))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.textSecondary)
                    .tracking(0.08)

                ForEach(CASCategoryFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedCategory = filter
                        }
                    } label: {
                        Text(filter.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedCategory == filter ? .white : Color.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                selectedCategory == filter
                                    ? LinearGradient(
                                        colors: [Color.accent, Color.accent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : Color.surface
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    selectedCategory == filter
                                        ? Color.accent
                                        : Color.hairline,
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Status filter pills
                ForEach(CASStatusFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedStatus = filter
                        }
                    } label: {
                        Text(filter.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedStatus == filter ? .white : Color.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedStatus == filter
                                    ? Color.accent
                                    : Color.surface
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    selectedStatus == filter
                                        ? Color.accent
                                        : Color.hairline,
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Search bar
            HStack(spacing: 8) {
                AstraIconView(.search, size: 13)
                    .foregroundColor(Color.textSecondary)

                TextField(String(localized: "common.search"), text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textPrimary)

                if !searchText.isBlank {
                    Button {
                        searchText = ""
                    } label: {
                        AstraIconView(.cancel, size: 14)
                            .foregroundColor(Color.textSecondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.hairline, lineWidth: 1))
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            AstraIconView(.favorite, size: 48)
                .foregroundColor(Color.accentContainer)

            Text(String(localized: "cas.noActivities"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color.textSecondary)

            Text(String(localized: "cas.noActivitiesHint"))
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)

            Button {
                showAddActivity = true
            } label: {
                HStack(spacing: 6) {
                    AstraIconView(.add)
                    Text(String(localized: "cas.addFirstActivity"))
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.accent, Color.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.accent.opacity(0.15), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Activity List Section

    private var activityListSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredEntries) { entry in
                activityCard(entry)
            }
        }
    }

    // MARK: - Activity Card

    private func activityCard(_ entry: CASEntry) -> some View {
        let isExpanded = expandedActivityID == entry.id

        return VStack(spacing: 0) {
            // Card header (always visible)
            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    expandedActivityID = isExpanded ? nil : entry.id
                }
            } label: {
                HStack(spacing: 16) {
                    // Category icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: entry.casCategory.color).opacity(0.15))
                            .frame(width: 44, height: 44)

                        AstraIconView(entry.casCategory.astraIcon, size: 18)
                            .foregroundColor(Color(hex: entry.casCategory.color))
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(entry.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.textPrimary)

                            if entry.isOngoing {
                                Text(String(localized: "cas.ongoing"))
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentContainer)
                                    .clipShape(Capsule())
                            }
                        }

                        HStack(spacing: 12) {
                            Text(entry.startDate.shortDateString)
                                .font(.system(size: 12))
                                .foregroundColor(Color.textSecondary)

                            Text(String(format: String(localized: "cas.hoursFormat"), String(format: "%.1f", entry.hoursSpent)))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.accent)

                            if let supervisor = entry.supervisor, !supervisor.isBlank {
                                HStack(spacing: 4) {
                                    AstraIconView(.person, size: 10)
                                    Text(supervisor)
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(Color.textSecondary)
                            }

                            Spacer()

                            // Status pill
                            statusPill(entry.status)

                            // Supervisor approved badge
                            if entry.supervisorApproved {
                                AstraIconView(.verified, size: 14)
                                    .foregroundColor(Color.semanticSuccess)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .buttonStyle(.plain)

            // Expanded detail area
            if isExpanded {
                expandedDetail(entry)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .astraCardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accent.opacity(0.6), lineWidth: isExpanded ? 1.5 : 0)
        )
    }

    // MARK: - Expanded Detail

    private func expandedDetail(_ entry: CASEntry) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Divider()
                .background(Color.hairline)
                .padding(.horizontal, 20)

            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "cas.description"))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.accent)
                    .tracking(0.08)

                Text(entry.description)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textPrimary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 20)

            // Tags
            if !entry.tags.isEmpty {
                HStack(spacing: 8) {
                    ForEach(entry.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 11))
                            .foregroundColor(Color.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.accentContainer)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
            }

            // Achieved outcomes
            if !entry.achievedOutcomes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "cas.learningOutcomes"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.accent)
                        .tracking(0.08)

                    FlowLayout(spacing: 8) {
                        ForEach(entry.achievedOutcomes, id: \.self) { outcomeID in
                            if let outcome = CASEntry.allOutcomes.first(where: { $0.id == outcomeID }) {
                                HStack(spacing: 4) {
                                    AstraIconView(.checkCircle, size: 11)
                                        .foregroundColor(Color.semanticSuccess)
                                    Text(outcome.name)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Color.textPrimary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.semanticSuccess.opacity(0.08))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            // Evidence section
            if !entry.evidence.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "cas.evidence"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.accent)
                        .tracking(0.08)

                    ForEach(entry.evidence, id: \.self) { evidencePath in
                        HStack(spacing: 8) {
                            AstraIconView(.description, size: 12)
                                .foregroundColor(Color.accent.opacity(0.7))
                            Text(URL(fileURLWithPath: evidencePath).lastPathComponent)
                                .font(.system(size: 12))
                                .foregroundColor(Color.textPrimary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentContainer)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 20)
            }

            // Reflections timeline
            reflectionsTimeline(entry)

            // Add reflection input
            addReflectionInput(entry)

            // Action buttons
            HStack(spacing: 12) {
                // Status cycling button
                Button {
                    cycleStatus(entry)
                } label: {
                    HStack(spacing: 6) {
                        AstraIconView(.refresh)
                        Text(String(localized: "cas.changeStatus"))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.surface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)

                // Toggle supervisor approval
                Button {
                    entry.supervisorApproved.toggle()
                } label: {
                    HStack(spacing: 6) {
                        AstraIconView(.verified, size: 14)
                        Text(entry.supervisorApproved ? String(localized: "cas.approved") : String(localized: "cas.markApproved"))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(entry.supervisorApproved ? Color.semanticSuccess : Color.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(entry.supervisorApproved ? Color.semanticSuccess.opacity(0.1) : Color.surface)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            entry.supervisorApproved ? Color.semanticSuccess : Color.hairline,
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                // Delete button
                Button {
                    deleteEntry(entry)
                } label: {
                    HStack(spacing: 6) {
                        AstraIconView(.delete)
                        Text(String(localized: "common.delete"))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.semanticDanger)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.semanticDanger.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Reflections Timeline

    private func reflectionsTimeline(_ entry: CASEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "cas.reflections"))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.accent)
                .tracking(0.08)

            if entry.reflections.isEmpty {
                HStack(spacing: 8) {
                    AstraIconView(.formatQuote, size: 12)
                        .foregroundColor(Color.textSecondary.opacity(0.5))
                    Text(String(localized: "cas.noReflectionsYet"))
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary.opacity(0.5))
                }
            } else {
                ForEach(entry.reflections) { reflection in
                    HStack(alignment: .top, spacing: 12) {
                        // Timeline dot
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color.accent)
                                .frame(width: 10, height: 10)
                            Rectangle()
                                .fill(Color.hairline)
                                .frame(width: 2, height: 20)
                        }
                        .frame(width: 10)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(reflection.date.shortDateString)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.textSecondary)

                            Text(reflection.content)
                                .font(.system(size: 14))
                                .foregroundColor(Color.textPrimary)
                                .lineSpacing(4)

                            // Linked outcomes in reflection
                            if !reflection.linkedOutcomes.isEmpty {
                                HStack(spacing: 6) {
                                    ForEach(reflection.linkedOutcomes, id: \.self) { outcomeID in
                                        if let outcome = CASEntry.allOutcomes.first(where: { $0.id == outcomeID }) {
                                            Text(outcome.name)
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(Color.accent)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Color.accentContainer)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Add Reflection Input

    @ViewBuilder
    private func addReflectionInput(_ entry: CASEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                AstraIconView(.editNote, size: 12)
                    .foregroundColor(Color.accent)
                Text(String(localized: "cas.addReflection"))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.accent)
                    .tracking(0.08)
            }

            TextEditor(text: $newReflectionText)
                .font(.system(size: 14))
                .foregroundColor(Color.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(12)
                .background(Color.accentContainer)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.hairline, lineWidth: 1)
                )

            HStack {
                Spacer()
                Button {
                    saveReflection(for: entry)
                } label: {
                    HStack(spacing: 6) {
                        AstraIconView(.check)
                        Text(String(localized: "cas.saveReflection"))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            colors: [Color.accent, Color.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(newReflectionText.isBlank)
                .opacity(newReflectionText.isBlank ? 0.5 : 1.0)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Status Pill

    private func statusPill(_ status: CASStatus) -> some View {
        let color: Color = switch status {
        case .planned:     Color.textSecondary
        case .inProgress:  Color.accent
        case .completed:   Color.semanticSuccess
        case .needsReview: Color.semanticWarning
        }

        return Text(status.displayName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Add Activity Sheet

    private var addActivitySheet: some View {
        VStack(spacing: 24) {
            // Sheet header
            HStack {
                Text(String(localized: "cas.newActivitySheetTitle"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color.textPrimary)
                Spacer()
                Button(String(localized: "common.cancel")) {
                    showAddActivity = false
                }
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .buttonStyle(.plain)
            }

            // Title
            VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "cas.titleLabel"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.accent)
                        .tracking(0.08)

                TextField(String(localized: "cas.activityTitlePlaceholder"), text: $newTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .foregroundColor(Color.textPrimary)
                    .padding(12)
                    .background(Color.accentContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.hairline, lineWidth: 1)
                    )
            }

            // Description
            VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "cas.description"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.accent)
                        .tracking(0.08)

                TextEditor(text: $newDescription)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(Color.accentContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.hairline, lineWidth: 1)
                    )
            }

            // Category selector
            VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "cas.category"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.accent)
                        .tracking(0.08)

                HStack(spacing: 12) {
                    ForEach(CASCategory.allCases, id: \.self) { category in
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                newCategory = category
                            }
                        } label: {
                            HStack(spacing: 6) {
                                AstraIconView(category.astraIcon, size: 13)
                                Text(category.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(newCategory == category ? .white : Color.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                newCategory == category
                                    ? LinearGradient(
                                        colors: [Color.accent, Color.accent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : Color.surface
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    newCategory == category ? Color.accent : Color.hairline,
                                    lineWidth: 1
                                )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Hours & Supervisor row
            HStack(spacing: 16) {
                // Hours
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "cas.hoursLabel"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.accent)
                        .tracking(0.08)

                    HStack(spacing: 8) {
                        TextField("0", value: $newHours, format: .number)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.textPrimary)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .padding(10)
                            .background(Color.accentContainer)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.hairline, lineWidth: 1)
                            )

                        Stepper("", value: $newHours, in: 0...100, step: 0.5)
                            .labelsHidden()
                    }
                }

                // Supervisor
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "cas.supervisorLabel"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.accent)
                        .tracking(0.08)

                    TextField(String(localized: "cas.supervisorPlaceholder"), text: $newSupervisor)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundColor(Color.textPrimary)
                        .padding(10)
                        .background(Color.accentContainer)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.hairline, lineWidth: 1)
                        )
                }

                // Ongoing toggle
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "cas.ongoingLabel"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.accent)
                        .tracking(0.08)

                    Toggle("", isOn: $newIsOngoing)
                        .toggleStyle(.switch)
                        .tint(Color.accent)
                }
            }

            // Save button
            HStack {
                Spacer()
                Button {
                    saveNewActivity()
                } label: {
                    HStack(spacing: 8) {
                        AstraIconView(.addCircle)
                        Text(String(localized: "cas.createActivity"))
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color.accent, Color.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.accent.opacity(0.15), radius: 10, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .disabled(newTitle.isBlank)
                .opacity(newTitle.isBlank ? 0.5 : 1.0)
            }
        }
        .padding(28)
        .frame(width: 520)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.accent.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: Color.accent.opacity(0.15), radius: 16, x: 0, y: 4)
    }

    // MARK: - Outcomes Checklist Sheet

    private var outcomesChecklistSheet: some View {
        VStack(spacing: 24) {
            HStack {
                Text(String(localized: "cas.learningOutcomes"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color.textPrimary)
                Spacer()
                Button(String(localized: "common.close")) {
                    showOutcomesPanel = false
                }
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .buttonStyle(.plain)
            }

            Text(String(localized: "cas.outcomesNote"))
                .font(.system(size: 13))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.leading)

            // Outcomes list with aggregate status
            ForEach(CASEntry.allOutcomes) { outcome in
                let isAchieved = entries.contains { $0.achievedOutcomes.contains(outcome.id) }
                let achievingEntries = entries.filter { $0.achievedOutcomes.contains(outcome.id) }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(isAchieved ? Color.semanticSuccess.opacity(0.15) : Color.accentContainer)
                                .frame(width: 28, height: 28)

                            AstraIconView(isAchieved ? .check : .circle, size: 13)
                                .foregroundColor(isAchieved ? Color.semanticSuccess : Color.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(outcome.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.textPrimary)

                            Text(outcome.description)
                                .font(.system(size: 12))
                                .foregroundColor(Color.textSecondary)
                        }

                        Spacer()

                        if isAchieved {
                            Text("\(achievingEntries.count)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.semanticSuccess)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.semanticSuccess.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }

                    // Show which activities achieved this outcome
                    if isAchieved && !achievingEntries.isEmpty {
                        HStack(spacing: 6) {
                            Text(String(localized: "cas.achievedIn"))
                                .font(.system(size: 11))
                                .foregroundColor(Color.textSecondary)

                            ForEach(achievingEntries) { entry in
                                Text(entry.title)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.accentContainer)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.leading, 38)
                    }
                }
                .padding(.vertical, 8)
            }

            // Summary bar
            HStack {
                Text(String(format: String(localized: "cas.outcomesAchieved"), achievedOutcomeCount))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(
                        achievedOutcomeCount == 7 ? Color.semanticSuccess : Color.textSecondary
                    )

                Spacer()

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentContainer)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        achievedOutcomeCount == 7 ? Color.semanticSuccess : Color.accent,
                                        achievedOutcomeCount == 7 ? Color.semanticSuccess.opacity(0.7) : Color.accent
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * (Double(achievedOutcomeCount) / 7.0), height: 8)
                    }
                }
                .frame(width: 160, height: 8)
            }
            .padding(16)
            .background(Color.accentContainer.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(28)
        .frame(width: 560)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.accent.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: Color.accent.opacity(0.15), radius: 16, x: 0, y: 4)
    }

    // MARK: - Actions

    private func saveNewActivity() {
        guard !newTitle.isBlank else { return }

        let entry = CASEntry(
            title: newTitle.trimmed,
            description: newDescription.trimmed,
            casCategory: newCategory,
            hoursSpent: newHours,
            isOngoing: newIsOngoing,
            supervisor: newSupervisor.isBlank ? nil : newSupervisor.trimmed,
            status: .planned
        )

        // Assign hours to the correct category
        switch newCategory {
        case .creativity:
            entry.creativityHours = newHours
        case .activity:
            entry.activityHours = newHours
        case .service:
            entry.serviceHours = newHours
        }

        modelContext.insert(entry)

        // Reset form
        newTitle = ""
        newDescription = ""
        newCategory = .creativity
        newSupervisor = ""
        newHours = 0
        newIsOngoing = false
        showAddActivity = false
    }

    private func saveReflection(for entry: CASEntry) {
        guard !newReflectionText.isBlank else { return }

        let reflection = CASReflection(
            date: .now,
            content: newReflectionText.trimmed,
            linkedOutcomes: []
        )

        entry.reflections.append(reflection)
        entry.status = .inProgress
        newReflectionText = ""
    }

    private func cycleStatus(_ entry: CASEntry) {
        switch entry.status {
        case .planned:     entry.status = .inProgress
        case .inProgress:  entry.status = .completed
        case .completed:   entry.status = .needsReview
        case .needsReview: entry.status = .planned
        }
    }

    private func deleteEntry(_ entry: CASEntry) {
        expandedActivityID = nil
        modelContext.delete(entry)
    }
}

// MARK: - Category Filter

enum CASCategoryFilter: String, CaseIterable {
    case all
    case creativity
    case activity
    case service

    var displayName: String {
        switch self {
        case .all:        return String(localized: "common.all")
        case .creativity: return String(localized: "cas.creativity")
        case .activity:   return String(localized: "cas.activity")
        case .service:    return String(localized: "cas.service")
        }
    }
}

// MARK: - Status Filter

enum CASStatusFilter: String, CaseIterable {
    case all
    case planned
    case inProgress
    case completed
    case needsReview

    var displayName: String {
        switch self {
        case .all:        return String(localized: "common.all")
        case .planned:    return String(localized: "cas.statusPlanned")
        case .inProgress: return String(localized: "cas.statusActive")
        case .completed:  return String(localized: "cas.statusDone")
        case .needsReview: return String(localized: "cas.statusReview")
        }
    }
}

// MARK: - Flow Layout

/// A simple flow layout that arranges views in a wrapping horizontal flow,
/// similar to CSS flexbox with wrap. Used for tags and outcome pills.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private struct LayoutResult {
        var size: CGSize
        var positions: [CGPoint]
        var sizes: [CGSize]
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> LayoutResult {
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.dimensions(in: .unspecified)
            sizes.append(size)

            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX - spacing)
        }

        return LayoutResult(
            size: CGSize(width: maxWidth, height: currentY + lineHeight),
            positions: positions,
            sizes: sizes
        )
    }
}

// MARK: - Preview

#Preview {
    CASJournalView()
        
        .modelContainer(for: CASEntry.self, inMemory: true)
}
