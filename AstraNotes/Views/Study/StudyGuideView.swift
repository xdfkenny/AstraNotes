// StudyGuideView.swift — AstraNotes
// Study guide generator and viewer with Soft Cryo ice crystal design aesthetic.
// Features: collapsible topic sections, formula/key concept table,
// review checklist, topic summary cards in a grid, and markdown rendering.

import SwiftUI
import SwiftData

// MARK: - Study Guide View

struct StudyGuideView: View {

    // MARK: - Environment

    @Environment(\.themeManager) private var tm
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var selectedSubject: String = String(localized: "studyGuide.allSubjects")
    @State private var selectedNoteType: NoteType? = nil
    @State private var searchText: String = ""
    @State private var expandedSectionIDs: Set<UUID> = []
    @State private var selectedGuideID: UUID?
    @State private var showGuideDetail: Bool = false
    @State private var checklists: [UUID: Set<Int>] = [:] // guideID -> checked item indices

    // MARK: - Queries

    @Query private var allNotes: [GeneratedNote]
    @Query private var subjects: [Subject]

    // MARK: - Computed Properties

    private var subjectNames: [String] {
        let noteSubjects = Set(allNotes.compactMap { $0.subjectName })
        let subjectNames = Set(subjects.map { $0.name })
        let combined = noteSubjects.union(subjectNames)
        return [String(localized: "studyGuide.allSubjects")] + combined.sorted()
    }

    private var studyGuides: [GeneratedNote] {
        var result = allNotes.filter { $0.type == .studyGuide || $0.type == .summary }

        if selectedSubject != String(localized: "studyGuide.allSubjects") {
            result = result.filter { $0.subjectName == selectedSubject }
        }

        if let noteType = selectedNoteType, noteType == .studyGuide {
            result = allNotes.filter { $0.type == .studyGuide }
            if selectedSubject != String(localized: "studyGuide.allSubjects") {
                result = result.filter { $0.subjectName == selectedSubject }
            }
        }

        if !searchText.isBlank {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.content.lowercased().contains(query) ||
                $0.tags.contains { $0.lowercased().contains(query) }
            }
        }

        return result.sorted { $0.dateGenerated > $1.dateGenerated }
    }

    private var topicSections: [TopicSection] {
        parseTopicSections(from: studyGuides)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection
                filtersSection

                if studyGuides.isEmpty {
                    emptyState
                } else {
                    topicSummaryGrid
                    collapsibleSections
                    formulaTable
                    reviewChecklist
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CryoColors.background(tm))
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("❄️")
                        .font(.system(size: 24))
                    Text(String(localized: "studyGuide.title"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(CryoColors.foreground(tm))
                }

                Text(String(localized: "studyGuide.subtitle"))
                    .font(.system(size: 14))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
            }

            Spacer()

            HStack(spacing: 12) {
                // Guide count pill
                HStack(spacing: 6) {
                    Text("\(studyGuides.count)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(CryoColors.accent(tm))
                    Text(String(localized: "studyGuide.guides"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(CryoColors.backgroundWarm(tm))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(CryoColors.border(tm), lineWidth: 1))

                // Total word count
                HStack(spacing: 6) {
                    Image(systemName: "textformat.abc")
                        .font(.system(size: 11))
                        .foregroundColor(CryoColors.accentDark(tm))
                    Text(totalWordCount)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(CryoColors.foreground(tm))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(CryoColors.backgroundWarm(tm))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(CryoColors.border(tm), lineWidth: 1))
            }
        }
    }

    private var totalWordCount: String {
        let count = studyGuides.reduce(0) { $0 + $1.wordCount }
        if count >= 1000 {
            return String(format: String(localized: "studyGuide.wordCountK"), Double(count) / 1000.0)
        }
        return String(format: String(localized: "studyGuide.words"), count)
    }

    // MARK: - Filters Section

    private var filtersSection: some View {
        HStack(spacing: 12) {
            // Subject picker
            Menu {
                ForEach(subjectNames, id: \.self) { subject in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedSubject = subject
                        }
                    } label: {
                        HStack {
                            Text(subject)
                            if selectedSubject == subject {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "book")
                    Text(selectedSubject)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(CryoColors.foreground(tm))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(CryoColors.backgroundWarm(tm))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(CryoColors.border(tm), lineWidth: 1))
            }
            #if os(macOS)
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            #endif

            // Type filter pills
            HStack(spacing: 8) {
                filterPill(label: String(localized: "studyGuide.all"), isActive: selectedNoteType == nil) {
                    selectedNoteType = nil
                }
                filterPill(label: String(localized: "studyGuide.filterStudyGuides"), isActive: selectedNoteType == .studyGuide) {
                    selectedNoteType = .studyGuide
                }
                filterPill(label: String(localized: "studyGuide.filterSummaries"), isActive: selectedNoteType == .summary) {
                    selectedNoteType = .summary
                }
            }

            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
                TextField(String(localized: "studyGuide.searchGuides"), text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(CryoColors.foreground(tm))
                    .frame(width: 180)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(CryoColors.backgroundWarm(tm))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(CryoColors.border(tm), lineWidth: 1))
        }
    }

    private func filterPill(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isActive ? .white : CryoColors.foreground(tm))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    isActive
                        ? LinearGradient(
                            colors: [CryoColors.accent(tm), CryoColors.accentDark(tm)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : CryoColors.backgroundWarm(tm)
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        isActive ? CryoColors.accent(tm) : CryoColors.border(tm),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(CryoColors.frost(tm))

            Text(String(localized: "studyGuide.noGuides"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(CryoColors.foregroundMuted(tm))

            Text(String(localized: "studyGuide.noGuidesHint"))
                .font(.system(size: 14))
                .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Topic Summary Cards Grid

    private var topicSummaryGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 12))
                    .foregroundColor(CryoColors.accentDark(tm))
                Text(String(localized: "studyGuide.topicSummaries"))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(CryoColors.accentDark(tm))
                    .tracking(0.08)

                Spacer()

                Text("\(studyGuides.count) \(String(localized: "studyGuide.guides"))")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(studyGuides) { note in
                    topicSummaryCard(note)
                }
            }
        }
    }

    private func topicSummaryCard(_ note: GeneratedNote) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Card header
            HStack {
                // Type icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(CryoColors.accentGlow(tm))
                        .frame(width: 36, height: 36)

                    Image(systemName: note.type.icon)
                        .font(.system(size: 16))
                        .foregroundColor(CryoColors.accent(tm))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(note.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(CryoColors.foreground(tm))
                        .lineLimit(1)

                    if let subject = note.subjectName {
                        Text(subject)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(CryoColors.foregroundMuted(tm))
                    }
                }

                Spacer()

                // Favorite indicator
                if note.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(CryoColors.warning(tm))
                }
            }

            // Preview text
            Text(contentPreview(note.content))
                .font(.system(size: 13))
                .foregroundColor(CryoColors.foregroundMuted(tm))
                .lineLimit(3)
                .lineSpacing(3)

            // Tags
            if !note.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(note.tags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(CryoColors.accent(tm))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(CryoColors.accentGlow(tm))
                            .clipShape(Capsule())
                    }

                    if note.tags.count > 3 {
                        Text("+\(note.tags.count - 3)")
                            .font(.system(size: 10))
                            .foregroundColor(CryoColors.foregroundMuted(tm))
                    }
                }
            }

            // Footer
            HStack {
                Text(note.displayDate)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.6))

                Spacer()

                Text(formatWordCount(note.wordCount))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(CryoColors.accentDark(tm))

                if !note.sourceModel.isBlank {
                    Text(note.sourceModel)
                        .font(.system(size: 10))
                        .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.4))
                }
            }
        }
        .padding(20)
        .cryoCardStyle(tm)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(CryoColors.crystalBorderGradient(tm), lineWidth: note.isFavorite ? 1.5 : 0)
        )
        #if os(macOS)
        .onHover { isHovered in
            withAnimation(.easeOut(duration: 0.2)) {
                expandedSectionIDs.insert(note.id)
            }
        }
        #endif
    }

    private func contentPreview(_ content: String) -> String {
        // Strip markdown formatting for a plain-text preview
        var cleaned = content
        // Remove heading markers
        cleaned = cleaned.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)
        // Remove bold/italic markers
        cleaned = cleaned.replacingOccurrences(of: #"[\*_]{1,2}"#, with: "", options: .regularExpression)
        // Remove links
        cleaned = cleaned.replacingOccurrences(of: #"\[([^\]]+)\]\([^\)]+\)"#, with: "$1", options: .regularExpression)
        // Collapse whitespace
        cleaned = cleaned.replacingOccurrences(of: #"\n{2,}"#, with: " ", options: .regularExpression)
        return cleaned.trimmed
    }

    private func formatWordCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: String(localized: "studyGuide.wordCountK"), Double(count) / 1000.0)
        }
        return String(format: String(localized: "studyGuide.words"), count)
    }

    // MARK: - Collapsible Sections

    private var collapsibleSections: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.indent")
                    .font(.system(size: 12))
                    .foregroundColor(CryoColors.accentDark(tm))
                Text(String(localized: "studyGuide.guideContent"))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(CryoColors.accentDark(tm))
                    .tracking(0.08)
            }

            LazyVStack(spacing: 12) {
                ForEach(studyGuides) { note in
                    collapsibleGuideSection(note)
                }
            }
        }
    }

    private func collapsibleGuideSection(_ note: GeneratedNote) -> some View {
        let isExpanded = expandedSectionIDs.contains(note.id)
        let parsedSections = parseMarkdownSections(note.content)

        return VStack(spacing: 0) {
            // Section header
            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    if isExpanded {
                        expandedSectionIDs.remove(note.id)
                    } else {
                        expandedSectionIDs.insert(note.id)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    // Chevron
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(CryoColors.accent(tm))
                        .frame(width: 16)

                    // Title
                    Text(note.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(CryoColors.foreground(tm))

                    Spacer()

                    // Info pills
                    HStack(spacing: 8) {
                        Text(formatWordCount(note.wordCount))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(CryoColors.foregroundMuted(tm))

                        Text(String(format: String(localized: "studyGuide.sections"), parsedSections.count))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(CryoColors.accentDark(tm))
                    }
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded && !parsedSections.isEmpty {
                VStack(spacing: 12) {
                    Divider()
                        .background(CryoColors.border(tm))
                        .padding(.horizontal, 16)

                    ForEach(Array(parsedSections.enumerated()), id: \.offset) { index, section in
                        VStack(alignment: .leading, spacing: 8) {
                            // Section heading
                            Text(section.heading)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(CryoColors.accent(tm))
                                .padding(.horizontal, 4)

                            // Section content
                            Text(section.content)
                                .font(.system(size: 13))
                                .foregroundColor(CryoColors.foreground(tm))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)

                            if index < parsedSections.count - 1 {
                                Divider()
                                    .background(CryoColors.frost(tm))
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Full content link
                    Button {
                        selectedGuideID = note.id
                        showGuideDetail = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.richtext")
                            Text(String(localized: "studyGuide.viewFullMarkdown"))
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(CryoColors.accent(tm))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(CryoColors.accentGlow(tm))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cryoCardStyle(tm)
    }

    // MARK: - Formula Table

    private var formulaTable: some View {
        let formulas = extractFormulas(from: studyGuides)

        if formulas.isEmpty { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "function")
                        .font(.system(size: 12))
                        .foregroundColor(CryoColors.accentDark(tm))
                    Text(String(localized: "studyGuide.keyFormulas"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(CryoColors.accentDark(tm))
                        .tracking(0.08)

                    Spacer()

                    Text(String(format: String(localized: "studyGuide.items"), formulas.count))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                }

                // Table
                VStack(spacing: 0) {
                    // Table header
                    HStack(spacing: 0) {
                        Text(String(localized: "studyGuide.formulaConcept"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(String(localized: "studyGuide.formulaSubject"))
                            .frame(width: 140, alignment: .center)
                        Text(String(localized: "studyGuide.formulaSource"))
                            .frame(width: 160, alignment: .leading)
                    }
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CryoColors.accentDark(tm))
                    .tracking(0.06)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(CryoColors.frost(tm))

                    Divider().background(CryoColors.border(tm))

                    ForEach(Array(formulas.enumerated()), id: \.offset) { index, formula in
                        HStack(spacing: 0) {
                            Text(formula.content)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(CryoColors.foreground(tm))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(formula.subject)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(CryoColors.accentDark(tm))
                                .frame(width: 140, alignment: .center)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(CryoColors.accentGlow(tm))
                                .clipShape(Capsule())

                            Text(formula.source)
                                .font(.system(size: 12))
                                .foregroundColor(CryoColors.foregroundMuted(tm))
                                .frame(width: 160, alignment: .leading)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if index < formulas.count - 1 {
                            Divider()
                                .background(CryoColors.frost(tm))
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .cryoCardStyle(tm, cornerRadius: 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CryoColors.border(tm), lineWidth: 1)
                )
            }
        )
    }

    // MARK: - Review Checklist

    private var reviewChecklist: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "checklist")
                    .font(.system(size: 12))
                    .foregroundColor(CryoColors.accentDark(tm))
                Text(String(localized: "studyGuide.reviewChecklist"))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(CryoColors.accentDark(tm))
                    .tracking(0.08)

                Spacer()

                let totalItems = studyGuides.count
                let checkedCount = studyGuides.filter { note in
                    let items = checklists[note.id, default: []]
                    return items.count >= 3 // 3 items per guide
                }.count

                Text(String(format: String(localized: "studyGuide.reviewed"), checkedCount, totalItems))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
            }

            LazyVStack(spacing: 10) {
                ForEach(studyGuides) { note in
                    reviewChecklistRow(note)
                }
            }
        }
    }

    private func reviewChecklistRow(_ note: GeneratedNote) -> some View {
        let checked = checklists[note.id, default: Set<Int>]()
        let items = checklistItems
        let completedCount = items.filter { checked.contains($0.id) }.count

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                // Progress indicator
                ZStack {
                    Circle()
                        .stroke(CryoColors.frost(tm), lineWidth: 3)
                        .frame(width: 32, height: 32)

                    Circle()
                        .trim(from: 0, to: Double(completedCount) / Double(items.count))
                        .stroke(
                            completedCount == items.count ? CryoColors.success(tm) : CryoColors.accent(tm),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))

                    if completedCount == items.count {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(CryoColors.success(tm))
                    } else {
                        Text("\(completedCount)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(CryoColors.accent(tm))
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(note.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(CryoColors.foreground(tm))
                        .lineLimit(1)

                    if let subject = note.subjectName {
                        Text(subject)
                            .font(.system(size: 11))
                            .foregroundColor(CryoColors.foregroundMuted(tm))
                    }
                }

                Spacer()

                if completedCount == items.count {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(CryoColors.success(tm))
                }
            }

            // Checklist items
            HStack(spacing: 12) {
                ForEach(items) { item in
                    let isChecked = checked.contains(item.id)

                    Button {
                        toggleChecklist(noteID: note.id, itemID: item.id)
                    } label: {
                        HStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(isChecked ? CryoColors.accent(tm) : CryoColors.border(tm), lineWidth: 1.5)
                                    .frame(width: 18, height: 18)

                                if isChecked {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(CryoColors.accent(tm))
                                }
                            }

                            Text(item.label)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(isChecked ? CryoColors.accent(tm) : CryoColors.foregroundMuted(tm))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 42)
        }
        .padding(16)
        .background(CryoColors.backgroundWarm(tm))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CryoColors.border(tm), lineWidth: 1)
        )
    }

    private let checklistItems: [ChecklistItem] = [
        ChecklistItem(id: 0, label: String(localized: "studyGuide.read")),
        ChecklistItem(id: 1, label: String(localized: "studyGuide.highlight")),
        ChecklistItem(id: 2, label: String(localized: "studyGuide.quiz")),
        ChecklistItem(id: 3, label: String(localized: "studyGuide.mastered"))
    ]

    // MARK: - Parsing Helpers

    private func parseMarkdownSections(_ markdown: String) -> [MarkdownSection] {
        var sections: [MarkdownSection] = []
        let lines = markdown.components(separatedBy: .newlines)

        var currentHeading = "Overview"
        var currentContent: [String] = []

        for line in lines {
            let trimmed = line.trimmed

            if trimmed.hasPrefix("# ") {
                // Save previous section
                if !currentContent.isEmpty || sections.isEmpty {
                    sections.append(MarkdownSection(
                        heading: currentHeading,
                        content: currentContent.joined(separator: "\n").trimmed
                    ))
                }
                currentHeading = trimmed.replacingOccurrences(of: "# ", with: "")
                currentContent = []
            } else if trimmed.hasPrefix("## ") || trimmed.hasPrefix("### ") {
                if !currentContent.isEmpty {
                    sections.append(MarkdownSection(
                        heading: currentHeading,
                        content: currentContent.joined(separator: "\n").trimmed
                    ))
                }
                currentHeading = trimmed.replacingOccurrences(of: #"^#{1,3}\s+"#, with: "", options: .regularExpression)
                currentContent = []
            } else {
                currentContent.append(line)
            }
        }

        // Don't forget the last section
        if !currentContent.isEmpty {
            sections.append(MarkdownSection(
                heading: currentHeading,
                content: currentContent.joined(separator: "\n").trimmed
            ))
        }

        // If no headings found, return the whole content as one section
        if sections.isEmpty && !markdown.isBlank {
            sections.append(MarkdownSection(heading: "Content", content: markdown.trimmed))
        }

        return sections
    }

    private func extractFormulas(from guides: [GeneratedNote]) -> [FormulaEntry] {
        var formulas: [FormulaEntry] = []

        for guide in guides {
            // Look for $$...$$ or $...$ patterns (LaTeX math)
            let patterns = [
                #"\$\$(.+?)\$\$"#,
                #"\$(.+?)\$"#
            ]

            for pattern in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { continue }
                let range = NSRange(guide.content.startIndex..., in: guide.content)
                let matches = regex.matches(in: guide.content, options: [], range: range)

                for match in matches {
                    guard let contentRange = Range(match.range(at: 1), in: guide.content) else { continue }
                    let formula = String(guide.content[contentRange]).trimmed

                    // Avoid duplicates
                    if !formulas.contains(where: { $0.content == formula }) {
                        formulas.append(FormulaEntry(
                            content: formula,
                            subject: guide.subjectName ?? "General",
                            source: guide.title
                        ))
                    }
                }
            }

            // Look for bullet points starting with common formula/concept markers
            let conceptLines = guide.content.components(separatedBy: .newlines).filter { line in
                let trimmed = line.trimmed
                return (trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ")) &&
                    (trimmed.lowercased().contains("formula") ||
                     trimmed.lowercased().contains("key concept") ||
                     trimmed.lowercased().contains("definition") ||
                     trimmed.lowercased().contains("theorem") ||
                     trimmed.lowercased().contains("equation"))
            }

            for line in conceptLines {
                let cleaned = line.trimmed
                    .replacingOccurrences(of: /^[-*]\s+/, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"[\*_]{1,2}"#, with: "", options: .regularExpression)

                if !formulas.contains(where: { $0.content == cleaned }) && !cleaned.isBlank {
                    formulas.append(FormulaEntry(
                        content: cleaned,
                        subject: guide.subjectName ?? "General",
                        source: guide.title
                    ))
                }
            }
        }

        return formulas.prefix(20).map { $0 } // Limit to 20 entries
    }

    private func parseTopicSections(from guides: [GeneratedNote]) -> [TopicSection] {
        // Group guides by subject/topic into sections
        var subjectMap: [String: [GeneratedNote]] = [:]

        for guide in guides {
            let key = guide.subjectName ?? "General"
            subjectMap[key, default: []].append(guide)
        }

        return subjectMap.map { key, notes in
            TopicSection(
                id: UUID(),
                title: key,
                guides: notes
            )
        }.sorted { $0.title < $1.title }
    }

    // MARK: - Actions

    private func toggleChecklist(noteID: UUID, itemID: Int) {
        if checklists[noteID] == nil {
            checklists[noteID] = Set<Int>()
        }
        if checklists[noteID]!.contains(itemID) {
            checklists[noteID]!.remove(itemID)
        } else {
            checklists[noteID]!.insert(itemID)
        }
    }
}

// MARK: - Data Models

struct TopicSection: Identifiable {
    var id: UUID
    var title: String
    var guides: [GeneratedNote]
}

struct MarkdownSection {
    var heading: String
    var content: String
}

struct FormulaEntry: Identifiable {
    var id = UUID()
    var content: String
    var subject: String
    var source: String
}

struct ChecklistItem: Identifiable {
    var id: Int
    var label: String
}

// MARK: - Preview

#Preview {
    StudyGuideView()
        .environment(ThemeManager())
        .modelContainer(for: GeneratedNote.self, inMemory: true)
}
