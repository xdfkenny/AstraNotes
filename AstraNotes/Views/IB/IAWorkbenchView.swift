// IAWorkbenchView.swift — AstraNotes
// Internal Assessment workbench with per-subject templates.
// Dashboard-style status cards for each section, completion indicators,
// word count tracker, and reflection areas with the Soft Cryo aesthetic.

import SwiftUI
import SwiftData

// MARK: - IA Workbench View

struct IAWorkbenchView: View {

    // MARK: - Environment

    @Environment(\.themeManager) private var tm
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
        .background(CryoColors.background(tm))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("chart.bar")
                    .font(.system(size: 22))
                    .foregroundStyle(CryoColors.accent(tm))
                Text(String(localized: "ia.title"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(CryoColors.foreground(tm))
            }

            Text(String(localized: "ia.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(CryoColors.foregroundMuted(tm))

            HStack {
                Spacer()
                Text("^[\(assessments.count) IA](inflect: true)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm))

                Button {
                    createNewIA()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text(String(localized: "ia.newIA"))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(CryoColors.primaryGradient(tm))
                    .clipShape(Capsule())
                    .shadow(color: CryoColors.shadowGlow(tm), radius: 8, x: 0, y: 2)
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
                Image(systemName: "book")
                    .font(.system(size: 12))
                    .foregroundColor(CryoColors.accent(tm))

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
                            .foregroundColor(CryoColors.foreground(tm))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(CryoColors.foregroundMuted(tm))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(CryoColors.backgroundWarm(tm))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(CryoColors.border(tm), lineWidth: 1)
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
                            .foregroundColor(selectedIAType == type ? .white : CryoColors.foreground(tm))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedIAType == type
                                    ? CryoColors.primaryGradient(tm)
                                    : CryoColors.backgroundWarm(tm)
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedIAType == type
                                            ? CryoColors.accent(tm)
                                            : CryoColors.border(tm),
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
                icon: "folder",
                color: CryoColors.accent(tm)
            )

            overviewStatCard(
                title: String(localized: "ia.inProgress"),
                value: "\(filteredAssessments.filter { $0.status == .inProgress }.count)",
                icon: "hourglass",
                color: CryoColors.warning(tm)
            )

            overviewStatCard(
                title: String(localized: "ia.submitted"),
                value: "\(filteredAssessments.filter { $0.status == .submitted }.count)",
                icon: "checkmark.circle",
                color: CryoColors.success(tm)
            )

            overviewStatCard(
                title: String(localized: "ia.avgProgress"),
                value: filteredAssessments.isEmpty
                    ? "0%"
                    : "\(Int(filteredAssessments.map(\.progress).reduce(0, +) / Double(max(filteredAssessments.count, 1)) * 100))%",
                icon: "chart.line.uptrend.xyaxis",
                color: CryoColors.crystal(tm)
            )
        }
    }

    private func overviewStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .monospaced, family: "JetBrains Mono"))
                .foregroundColor(CryoColors.foreground(tm))

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(CryoColors.foregroundMuted(tm))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .cryoCardStyle(tm)
    }

    // MARK: - IA Selection (no IA selected)

    private var iaSelectionSection: some View {
        VStack(spacing: 16) {
            if filteredAssessments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 40))
                        .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.3))
                    Text(String(localized: "ia.noAssessments"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(CryoColors.foreground(tm))
                    Text(String(localized: "ia.noAssessmentsHint"))
                        .font(.system(size: 13))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
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
                    .foregroundColor(CryoColors.foreground(tm))
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
                Label(ia.subject, systemImage: "book")
                    .font(.system(size: 12))
                    .foregroundColor(CryoColors.foregroundMuted(tm))

                Label(ia.type.displayName, systemImage: "doc.text")
                    .font(.system(size: 12))
                    .foregroundColor(CryoColors.foregroundMuted(tm))

                Spacer()

                Text("\(ia.wordCount) / \(ia.maxWordCount)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced, family: "JetBrains Mono"))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
            }

            // Progress bar
            iaProgressBar(ia.progress)

            // Section completion count
            let completedSections = ia.sections.filter(\.isComplete).count
            Text(String(localized: "ia.sectionsComplete \(completedSections) \(ia.sections.count)"))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(CryoColors.foregroundMuted(tm))
        }
        .padding(16)
        .cryoCardStyle(tm)
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
                        .foregroundColor(CryoColors.foreground(tm))

                    HStack(spacing: 8) {
                        Text(ia.subject)
                            .font(.system(size: 13))
                            .foregroundColor(CryoColors.accent(tm))

                        Text(ia.type.displayName)
                            .font(.system(size: 12))
                            .foregroundColor(CryoColors.foregroundMuted(tm))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(CryoColors.frost(tm))
                            .clipShape(Capsule())

                        Text(ia.status.displayName)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(iaStatusColor(ia.status))
                    }
                }

                Spacer()

                Text("\(Int(ia.progress * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .monospaced, family: "JetBrains Mono"))
                    .foregroundColor(CryoColors.accent(tm))
            }
            .padding(16)
            .cryoCardStyle(tm)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(CryoColors.crystalBorderGradient(tm), lineWidth: 2)
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
                    Image(systemName: "arrow.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text(String(localized: "ia.backToAllIAs"))
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(CryoColors.accentDark(tm))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(CryoColors.backgroundWarm(tm))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(CryoColors.border(tm), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Section Status Grid

    private func sectionStatusGrid(_ ia: InternalAssessment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "ia.sections"), icon: "list.bullet.rectangle")

            if ia.sections.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 28))
                        .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.3))
                    Text(String(localized: "ia.noSectionsDefined"))
                        .font(.system(size: 13))
                        .foregroundColor(CryoColors.foregroundMuted(tm))

                    Button {
                        addDefaultSections(to: ia)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .semibold))
                            Text(String(localized: "ia.addDefaultSections"))
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(CryoColors.primaryGradient(tm))
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
                        .stroke(CryoColors.border(tm), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if section.isComplete {
                        Circle()
                            .fill(CryoColors.accent(tm))
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(CryoColors.foreground(tm))

                    Text(String(localized: "ia.sectionNumber \(section.order + 1)"))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                }

                Spacer()

                // Toggle completion
                Button {
                    section.isComplete.toggle()
                } label: {
                    Image(systemName: section.isComplete ? "checkmark.seal.fill" : "circle.dashed")
                        .font(.system(size: 16))
                        .foregroundColor(section.isComplete ? CryoColors.success(tm) : CryoColors.foregroundMuted(tm).opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            // Content preview
            if !section.content.isEmpty {
                Text(section.content)
                    .font(.system(size: 12))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
                    .lineLimit(3)
            } else {
                Text(String(localized: "ia.noContentYet"))
                    .font(.system(size: 12))
                    .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.4))
            }

            // Word count for this section
            Text(String(localized: "ia.wordCountLabel \(section.content.wordCount)"))
                .font(.system(size: 10, design: .monospaced, family: "JetBrains Mono"))
                .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.6))
        }
        .padding(14)
        .cryoCardStyle(tm)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    section.isComplete
                        ? CryoColors.accent(tm).opacity(0.4)
                        : CryoColors.border(tm),
                    lineWidth: section.isComplete ? 2 : 1
                )
        )
    }

    // MARK: - Reflection Section

    private func reflectionSection(_ ia: InternalAssessment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "ia.reflections"), icon: "pencil.and.outline")

            HStack(spacing: 16) {
                reflectionCard(
                    title: String(localized: "ia.reflectionExploration"),
                    text: $explorationReflection,
                    icon: "lightbulb",
                    placeholder: String(localized: "ia.reflectionExplorationPlaceholder")
                )

                reflectionCard(
                    title: String(localized: "ia.reflectionAnalysis"),
                    text: $analysisReflection,
                    icon: "magnifyingglass",
                    placeholder: String(localized: "ia.reflectionAnalysisPlaceholder")
                )

                reflectionCard(
                    title: String(localized: "ia.reflectionEvaluation"),
                    text: $evaluationReflection,
                    icon: "eye",
                    placeholder: String(localized: "ia.reflectionEvaluationPlaceholder")
                )
            }
        }
    }

    private func reflectionCard(
        title: String,
        text: Binding<String>,
        icon: String,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(CryoColors.accent(tm))
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(CryoColors.foreground(tm))
            }

            TextEditor(text: text)
                .font(.system(size: 13))
                .foregroundColor(CryoColors.foreground(tm))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .padding(10)
                .background(CryoColors.backgroundWarm(tm))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(CryoColors.border(tm), lineWidth: 1)
                )

            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.system(size: 11))
                    .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cryoCardStyle(tm)
    }

    // MARK: - Word Count Tracker

    private func wordCountTracker(_ ia: InternalAssessment) -> some View {
        VStack(spacing: 16) {
            HStack {
                sectionLabel(String(localized: "ee.wordCount"), icon: "textformat")

                Spacer()

                let totalWords = ia.sections.reduce(0) { $0 + $1.content.wordCount }
                Text("\(totalWords)")
                    .font(.system(size: 32, weight: .bold, design: .monospaced, family: "JetBrains Mono"))
                    .foregroundColor(
                        totalWords > ia.maxWordCount
                            ? CryoColors.error(tm)
                            : CryoColors.accent(tm)
                    )

                Text("/ \(ia.maxWordCount)")
                    .font(.system(size: 18, weight: .regular, design: .monospaced, family: "JetBrains Mono"))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
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
                                .foregroundColor(CryoColors.foregroundMuted(tm))
                                .lineLimit(1)

                            Text("\(section.content.wordCount)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced, family: "JetBrains Mono"))
                                .foregroundColor(CryoColors.accent(tm))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(CryoColors.frost(tm))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(20)
        .cryoCardStyle(tm)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(CryoColors.crystalBorderGradient(tm), lineWidth: 2)
        )
    }

    // MARK: - Shared Components

    private func iaProgressBar(_ progress: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(CryoColors.frost(tm))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [CryoColors.accent(tm), CryoColors.accentDark(tm)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * min(max(progress, 0), 1), height: 6)
            }
        }
        .frame(height: 6)
    }

    private func sectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(CryoColors.accent(tm))
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(CryoColors.foreground(tm))
                .tracking(0.02)
        }
    }

    private func iaStatusColor(_ status: IAStatus) -> Color {
        switch status {
        case .planning:    return CryoColors.warning(tm)
        case .inProgress:  return CryoColors.accent(tm)
        case .underReview: return CryoColors.crystal(tm)
        case .submitted:   return CryoColors.success(tm)
        }
    }

    // MARK: - Actions

    private func createNewIA() {
        let ia = InternalAssessment(
            title: String(localized: "ia.defaultTitle \(assessments.count + 1)"),
            subject: "",
            subjectGroup: 4,
            type: selectedIAType,
            maxWordCount: defaultMaxWords(for: selectedIAType)
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
        .environment(ThemeManager())
        .modelContainer(for: InternalAssessment.self, inMemory: true)
}
