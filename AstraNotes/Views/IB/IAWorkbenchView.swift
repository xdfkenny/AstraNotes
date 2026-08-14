// IAWorkbenchView.swift — AstraNotes
// Internal Assessment workbench with per-subject templates.
// Dashboard-style status cards for each section, completion indicators,
// word count tracker, and reflection areas with the Astra design system.

import SwiftUI
import SwiftData

// MARK: - IA Workbench View

struct IAWorkbenchView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var selectedIA: InternalAssessment?
    @State private var selectedSubject: String = ""
    @State private var selectedIAType: IAType = .scientificExploration
    @State private var explorationReflection: String = ""
    @State private var analysisReflection: String = ""
    @State private var evaluationReflection: String = ""
    @State private var editingSectionID: UUID?
    @State private var showNewIA: Bool = false

    // MARK: - Queries

    @Query(sort: \InternalAssessment.dateStarted, order: .reverse) private var assessments: [InternalAssessment]

    // MARK: - Computed

    private var filteredAssessments: [InternalAssessment] {
        if selectedSubject.isEmpty {
            return assessments
        }
        return assessments.filter { $0.subject == selectedSubject }
    }

    private var subjectOptions: [String] {
        Array(Set(assessments.map { $0.subject })).sorted()
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection
                subjectAndTypeSelector
                iaOverviewSection

                if let ia = selectedIA {
                    iaDashboard(ia)
                } else {
                    iaSelectionSection
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceBackground)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                AstraIconView(.barChart, size: 22)
                    .foregroundStyle(Color.accent)
                Text(String(localized: "ia.title"))
                    .font(TypeScale.title)
                    .foregroundColor(Color.textPrimary)
            }

            Text(String(localized: "ia.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)

            HStack {
                Spacer()
                Text("^[\(assessments.count) IA](inflect: true)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color.textSecondary)

                Button {
                    createNewIA()
                } label: {
                    HStack(spacing: 6) {
                        AstraIconView(.add, size: 12)
                        Text(String(localized: "ia.newIA"))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accent)
                    .clipShape(Capsule())
                    .shadow(color: Color.accent.opacity(0.15), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Subject & Type Selector

    private var subjectAndTypeSelector: some View {
        HStack(spacing: 16) {
            // Subject filter
            HStack(spacing: 6) {
                AstraIconView(.menuBook, size: 12)
                    .foregroundColor(Color.accent)

                Menu {
                    Button(String(localized: "ia.allSubjects")) { selectedSubject = "" }
                    Divider()
                    ForEach(subjectOptions, id: \.self) { subject in
                        Button {
                            selectedSubject = subject
                        } label: {
                            Text(subject)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedSubject.isEmpty ? String(localized: "ia.allSubjects") : selectedSubject)
                            .font(.system(size: 13))
                            .foregroundColor(Color.textPrimary)
                        AstraIconView(.expandMore, size: 10)
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.surface)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.hairline, lineWidth: 1)
                    )
                }
                #if os(macOS)
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                #endif
            }

            // IA Type filter tabs
            HStack(spacing: 6) {
                ForEach(IAType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedIAType = type
                        }
                    } label: {
                        Text(type.displayName)
                            .font(.system(size: 12, weight: selectedIAType == type ? .semibold : .regular))
                            .foregroundColor(selectedIAType == type ? .white : Color.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedIAType == type
                                    ? Color.accent
                                    : Color.surface
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedIAType == type
                                            ? Color.accent
                                            : Color.hairline,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - IA Overview Statistics

    private var iaOverviewSection: some View {
        HStack(spacing: 16) {
            overviewStatCard(
                title: String(localized: "ia.totalIAs"),
                value: "\(filteredAssessments.count)",
                icon: .folder,
                color: Color.accent
            )

            overviewStatCard(
                title: String(localized: "ia.inProgress"),
                value: "\(filteredAssessments.filter { $0.status == .inProgress }.count)",
                icon: .hourglassEmpty,
                color: Color.semanticWarning
            )

            overviewStatCard(
                title: String(localized: "ia.submitted"),
                value: "\(filteredAssessments.filter { $0.status == .submitted }.count)",
                icon: .checkCircle,
                color: Color.semanticSuccess
            )

            overviewStatCard(
                title: String(localized: "ia.avgProgress"),
                value: filteredAssessments.isEmpty
                    ? "0%"
                    : "\(Int(filteredAssessments.map(\.progress).reduce(0, +) / Double(max(filteredAssessments.count, 1)) * 100))%",
                icon: .showChart,
                color: Color.accent.opacity(0.7)
            )
        }
    }

    private func overviewStatCard(title: String, value: String, icon: AstraIcon, color: Color) -> some View {
        VStack(spacing: 8) {
            AstraIconView(icon, size: 18)
                .foregroundColor(color)

            Text(value)
                .font(.astraMono(24, .bold))
                .foregroundColor(Color.textPrimary)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .astraCardStyle()
    }

    // MARK: - IA Selection (no IA selected)

    private var iaSelectionSection: some View {
        VStack(spacing: 16) {
            if filteredAssessments.isEmpty {
                VStack(spacing: 16) {
                    AstraIconView(.barChart, size: 40)
                        .foregroundColor(Color.textSecondary.opacity(0.3))
                    Text(String(localized: "ia.noAssessments"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.textPrimary)
                    Text(String(localized: "ia.noAssessmentsHint"))
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(filteredAssessments) { ia in
                        iaSummaryCard(ia)
                    }
                }
            }
        }
    }

    // MARK: - IA Summary Card

    private func iaSummaryCard(_ ia: InternalAssessment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(ia.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text(ia.status.displayName)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(iaStatusColor(ia.status))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(iaStatusColor(ia.status).opacity(0.1))
                    .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                Label { Text(ia.subject) } icon: { AstraIconView(.menuBook, size: 12) }
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)

                Label { Text(ia.type.displayName) } icon: { AstraIconView(.description, size: 12) }
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)

                Spacer()

                Text("\(ia.wordCount) / \(ia.maxWordCount)")
                    .font(.astraMono(12, .medium))
                    .foregroundColor(Color.textSecondary)
            }

            // Progress bar
            iaProgressBar(ia.progress)

            // Section completion count
            let completedSections = ia.sections.filter(\.isComplete).count
            Text(String(format: String(localized: "ia.sectionsComplete"), completedSections, ia.sections.count))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color.textSecondary)
        }
        .padding(16)
        .astraCardStyle()
        .onTapGesture {
            selectedIA = ia
            loadIA(ia)
        }
    }

    // MARK: - IA Dashboard (when selected)

    private func iaDashboard(_ ia: InternalAssessment) -> some View {
        VStack(spacing: 24) {
            // Title + status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ia.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color.textPrimary)

                    HStack(spacing: 8) {
                        Text(ia.subject)
                            .font(.system(size: 13))
                            .foregroundColor(Color.accent)

                        Text(ia.type.displayName)
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.accentContainer)
                            .clipShape(Capsule())

                        Text(ia.status.displayName)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(iaStatusColor(ia.status))
                    }
                }

                Spacer()

                Text("\(Int(ia.progress * 100))%")
                    .font(.astraMono(28, .bold))
                    .foregroundColor(Color.accent)
            }
            .padding(16)
            .astraCardStyle()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.accent.opacity(0.6), lineWidth: 2)
            )

            // Section status cards grid
            sectionStatusGrid(ia)

            // Reflection areas
            reflectionSection(ia)

            // Word count tracker
            wordCountTracker(ia)

            // Back button
            Button {
                saveIA(ia)
                selectedIA = nil
            } label: {
                HStack(spacing: 6) {
                    AstraIconView(.arrowBack, size: 12)
                    Text(String(localized: "ia.backToAllIAs"))
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(Color.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.hairline, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Section Status Grid

    private func sectionStatusGrid(_ ia: InternalAssessment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "ia.sections"), icon: .notes)

            if ia.sections.isEmpty {
                VStack(spacing: 12) {
                    AstraIconView(.notes, size: 28)
                        .foregroundColor(Color.textSecondary.opacity(0.3))
                    Text(String(localized: "ia.noSectionsDefined"))
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)

                    Button {
                        addDefaultSections(to: ia)
                    } label: {
                        HStack(spacing: 4) {
                            AstraIconView(.add, size: 11)
                            Text(String(localized: "ia.addDefaultSections"))
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.accent)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ], spacing: 14) {
                    ForEach(ia.sections) { section in
                        sectionCard(section, ia: ia)
                    }
                }
            }
        }
    }

    private func sectionCard(_ section: IASection, ia: InternalAssessment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with completion indicator
            HStack {
                // Completion circle
                ZStack {
                    Circle()
                        .stroke(Color.hairline, lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if section.isComplete {
                        Circle()
                            .fill(Color.accent)
                            .frame(width: 28, height: 28)

                        AstraIconView(.check, size: 12)
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.textPrimary)

                    Text(String(format: String(localized: "ia.sectionNumber"), section.order + 1))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color.textSecondary)
                }

                Spacer()

                // Toggle completion
                Button {
                    if let idx = ia.sections.firstIndex(where: { $0.id == section.id }) {
                        ia.sections[idx].isComplete.toggle()
                    }
                } label: {
                    AstraIconView(section.isComplete ? .verified : .radioButtonUnchecked, size: 16)
                        .foregroundColor(section.isComplete ? Color.semanticSuccess : Color.textSecondary.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            // Content preview
            if !section.content.isEmpty {
                Text(section.content)
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
                    .lineLimit(3)
            } else {
                Text(String(localized: "ia.noContentYet"))
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary.opacity(0.4))
            }

            // Word count for this section
            Text(String(format: String(localized: "ia.wordCountLabel"), section.content.wordCount))
                .font(.astraMono(10))
                .foregroundColor(Color.textSecondary.opacity(0.6))
        }
        .padding(14)
        .astraCardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    section.isComplete
                        ? Color.accent.opacity(0.4)
                        : Color.hairline,
                    lineWidth: section.isComplete ? 2 : 1
                )
        )
    }

    // MARK: - Reflection Section

    private func reflectionSection(_ ia: InternalAssessment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "ia.reflections"), icon: .editNote)

            HStack(spacing: 16) {
                reflectionCard(
                    title: String(localized: "ia.reflectionExploration"),
                    text: $explorationReflection,
                    icon: .lightbulb,
                    placeholder: String(localized: "ia.reflectionExplorationPlaceholder")
                )

                reflectionCard(
                    title: String(localized: "ia.reflectionAnalysis"),
                    text: $analysisReflection,
                    icon: .search,
                    placeholder: String(localized: "ia.reflectionAnalysisPlaceholder")
                )

                reflectionCard(
                    title: String(localized: "ia.reflectionEvaluation"),
                    text: $evaluationReflection,
                    icon: .visibility,
                    placeholder: String(localized: "ia.reflectionEvaluationPlaceholder")
                )
            }
        }
    }

    private func reflectionCard(
        title: String,
        text: Binding<String>,
        icon: AstraIcon,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                AstraIconView(icon, size: 12)
                    .foregroundColor(Color.accent)
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.textPrimary)
            }

            TextEditor(text: text)
                .font(.system(size: 13))
                .foregroundColor(Color.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .padding(10)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.hairline, lineWidth: 1)
                )

            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.system(size: 11))
                    .foregroundColor(Color.textSecondary.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .astraCardStyle()
    }

    // MARK: - Word Count Tracker

    private func wordCountTracker(_ ia: InternalAssessment) -> some View {
        VStack(spacing: 16) {
            HStack {
                sectionLabel(String(localized: "ee.wordCount"), icon: .textFields)

                Spacer()

                let totalWords = ia.sections.reduce(0) { $0 + $1.content.wordCount }
                Text("\(totalWords)")
                    .font(.astraMono(32, .bold))
                    .foregroundColor(
                        totalWords > ia.maxWordCount
                            ? Color.semanticDanger
                            : Color.accent
                    )

                Text("/ \(ia.maxWordCount)")
                    .font(.astraMono(18, .regular))
                    .foregroundColor(Color.textSecondary)
            }

            let ratio = min(1.0, Double(ia.sections.reduce(0) { $0 + $1.content.wordCount }) / Double(max(ia.maxWordCount, 1)))
            iaProgressBar(ratio)

            // Per-section breakdown
            if !ia.sections.isEmpty {
                HStack(spacing: 8) {
                    ForEach(ia.sections) { section in
                        VStack(spacing: 4) {
                            Text(section.title)
                                .font(.system(size: 10))
                                .foregroundColor(Color.textSecondary)
                                .lineLimit(1)

                            Text("\(section.content.wordCount)")
                                .font(.astraMono(13, .bold))
                                .foregroundColor(Color.accent)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentContainer)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(20)
        .astraCardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.accent.opacity(0.6), lineWidth: 2)
        )
    }

    // MARK: - Shared Components

    private func iaProgressBar(_ progress: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentContainer)
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        Color.accent
                    )
                    .frame(width: geometry.size.width * min(max(progress, 0), 1), height: 6)
            }
        }
        .frame(height: 6)
    }

    private func sectionLabel(_ title: String, icon: AstraIcon) -> some View {
        HStack(spacing: 6) {
            AstraIconView(icon, size: 12)
                .foregroundColor(Color.accent)
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color.textPrimary)
                .tracking(0.02)
        }
    }

    private func iaStatusColor(_ status: IAStatus) -> Color {
        switch status {
        case .planning:    return Color.semanticWarning
        case .inProgress:  return Color.accent
        case .underReview: return Color.accent.opacity(0.7)
        case .submitted:   return Color.semanticSuccess
        }
    }

    // MARK: - Actions

    private func createNewIA() {
        let ia = InternalAssessment(
            title: String(format: String(localized: "ia.defaultTitle"), assessments.count + 1),
            subject: "",
            subjectGroup: 4,
            maxWordCount: defaultMaxWords(for: selectedIAType),
            type: selectedIAType
        )
        modelContext.insert(ia)
        selectedIA = ia
        loadIA(ia)
    }

    private func defaultMaxWords(for type: IAType) -> Int {
        switch type {
        case .scientificExploration:     return 2000
        case .mathematicalExploration:   return 2000
        case .historicalInvestigation:   return 2000
        case .writtenTask:               return 1500
        case .oralWork:                  return 0
        case .fieldwork:                 return 2000
        case .artwork:                   return 1000
        case .other:                     return 2000
        }
    }

    private func loadIA(_ ia: InternalAssessment) {
        explorationReflection = ia.explorationReflection ?? ""
        analysisReflection = ia.analysisReflection ?? ""
        evaluationReflection = ia.evaluationReflection ?? ""
    }

    private func saveIA(_ ia: InternalAssessment) {
        ia.explorationReflection = explorationReflection.isEmpty ? nil : explorationReflection
        ia.analysisReflection = analysisReflection.isEmpty ? nil : analysisReflection
        ia.evaluationReflection = evaluationReflection.isEmpty ? nil : evaluationReflection
        ia.wordCount = ia.sections.reduce(0) { $0 + $1.content.wordCount }
    }

    private func addDefaultSections(to ia: InternalAssessment) {
        let defaults: [(String, Int)] = [
            ("Personal Engagement", 0),
            ("Exploration", 1),
            ("Analysis", 2),
            ("Evaluation", 3),
            ("Communication", 4)
        ]

        for (title, order) in defaults {
            let section = IASection(title: title, content: "", isComplete: false, order: order)
            ia.sections.append(section)
        }
    }
}

// MARK: - Preview

#Preview {
    IAWorkbenchView()
        
        .modelContainer(for: InternalAssessment.self, inMemory: true)
}
