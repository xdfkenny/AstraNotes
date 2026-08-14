// EETrackerView.swift — AstraNotes
// Extended Essay progress tracker with ice-blue gradient progress bars,
// RPPF reflection cards, meeting notes, and word count display
// with the Astra design system.

import SwiftUI
import SwiftData

// MARK: - EE Tracker View

struct EETrackerView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var selectedEE: ExtendedEssay?
    @State private var researchQuestion: String = ""
    @State private var rppfInitialText: String = ""
    @State private var rppfMidtermText: String = ""
    @State private var rppfFinalText: String = ""
    @State private var meetingSummary: String = ""
    @State private var meetingActionItem: String = ""
    @State private var essayContent: String = ""
    @State private var newMeetingNotes: [String] = []
    @State private var showNewEE: Bool = false
    @State private var selectedTab: EESectionTab = .exploration
    @State private var expandedMeeting: UUID?

    // MARK: - Queries

    @Query(sort: \ExtendedEssay.dateStarted, order: .reverse) private var essays: [ExtendedEssay]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection

                if let ee = selectedEE {
                    eeDashboard(ee)
                } else {
                    eeSelectionSection
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
                AstraIconView(.school, size: 22)
                    .foregroundStyle(Color.accent)
                Text(String(localized: "ee.title"))
                    .font(TypeScale.title)
                    .foregroundColor(Color.textPrimary)
            }

            Text(String(localized: "ee.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)

            HStack {
                Spacer()
                Text("^[\(essays.count) essay](inflect: true)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color.textSecondary)

                Button {
                    createNewEE()
                } label: {
                    HStack(spacing: 6) {
                        AstraIconView(.add, size: 12)
                        Text(String(localized: "ee.newEssay"))
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

    // MARK: - EE Selection (no EE selected)

    private var eeSelectionSection: some View {
        VStack(spacing: 16) {
            if essays.isEmpty {
                VStack(spacing: 16) {
                    AstraIconView(.school, size: 40)
                        .foregroundColor(Color.textSecondary.opacity(0.3))
                    Text(String(localized: "ee.noEssays"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.textPrimary)
                    Text(String(localized: "ee.noEssaysHint"))
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            } else {
                ForEach(essays) { ee in
                    eeSummaryCard(ee)
                }
            }
        }
    }

    // MARK: - EE Summary Card

    private func eeSummaryCard(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(ee.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.textPrimary)

                Spacer()

                Text(ee.status.displayName)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(statusColor(ee.status))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor(ee.status).opacity(0.1))
                    .clipShape(Capsule())
            }

            if !ee.researchQuestion.isEmpty {
                Text(ee.researchQuestion)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color.accent)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                Label { Text(ee.subject) } icon: { AstraIconView(.menuBook, size: 12) }
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)

                if let supervisor = ee.supervisor, !supervisor.isEmpty {
                    Label { Text(supervisor) } icon: { AstraIconView(.person, size: 12) }
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }

                Spacer()

                Text("\(ee.wordCount) / \(ee.maxWordCount)")
                    .font(.astraMono(12, .medium))
                    .foregroundColor(Color.textSecondary)
            }

            // Progress bar
            progressBar(for: ee.progress)
        }
        .padding(16)
        .astraCardStyle()
        .onTapGesture {
            selectedEE = ee
            loadEE(ee)
        }
    }

    // MARK: - EE Dashboard (when selected)

    private func eeDashboard(_ ee: ExtendedEssay) -> some View {
        VStack(spacing: 24) {
            // Research question + progress
            researchQuestionCard(ee)
            progressBarSection(ee)

            // Section navigation tabs
            sectionNavigationTabs

            // Content based on selected tab
            tabContent(for: ee)

            // RPPF reflections
            rppfReflectionSection(ee)

            // Meeting notes
            meetingNotesSection(ee)

            // Word count tracker
            wordCountSection(ee)

            // Back button
            Button {
                saveEE(ee)
                selectedEE = nil
            } label: {
                HStack(spacing: 6) {
                    AstraIconView(.arrowBack, size: 12)
                    Text(String(localized: "ee.backToAllEssays"))
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

    // MARK: - Research Question Card

    private func researchQuestionCard(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                AstraIconView(.help, size: 12)
                    .foregroundColor(Color.accent)
                Text(String(localized: "ee.researchQuestion"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.textPrimary)
            }

            TextEditor(text: $researchQuestion)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Color.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 48)
                .padding(12)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.hairline, lineWidth: 1)
                )

            // Subject + supervisor badges
            HStack(spacing: 8) {
                if !ee.subject.isEmpty {
                    HStack(spacing: 4) {
                        AstraIconView(.menuBook, size: 10)
                        Text(ee.subject)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentContainer)
                    .clipShape(Capsule())
                }

                if let supervisor = ee.supervisor, !supervisor.isEmpty {
                    HStack(spacing: 4) {
                        AstraIconView(.person, size: 10)
                        Text(supervisor)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentContainer)
                    .clipShape(Capsule())
                }

                Spacer()

                Text(ee.status.displayName)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(statusColor(ee.status))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor(ee.status).opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .astraCardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.accent.opacity(0.6), lineWidth: 2)
        )
    }

    // MARK: - Progress Bar Section

    private func progressBarSection(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(localized: "ee.overallProgress"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.textPrimary)

                Spacer()

                Text("\(Int(ee.progress * 100))%")
                    .font(.astraMono(14, .bold))
                    .foregroundColor(Color.accent)
            }

            progressBar(for: ee.progress)
        }
    }

    // MARK: - Section Navigation Tabs

    private var sectionNavigationTabs: some View {
        HStack(spacing: 8) {
            ForEach(EESectionTab.allCases) { tab in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        AstraIconView(tab.astraIcon, size: 12)
                        Text(tab.displayName)
                            .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                    }
                    .foregroundColor(selectedTab == tab ? .white : Color.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab
                            ? Color.accent
                            : Color.surface
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                selectedTab == tab
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

    // MARK: - Tab Content

    @ViewBuilder
    private func tabContent(for ee: ExtendedEssay) -> some View {
        switch selectedTab {
        case .exploration:
            explorationTab(ee)
        case .research:
            researchTab(ee)
        case .drafting:
            draftingTab(ee)
        case .review:
            reviewTab(ee)
        }
    }

    // MARK: - Exploration Tab

    private func explorationTab(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "ee.explorationPlanning"), icon: .lightbulb)

            VStack(alignment: .leading, spacing: 8) {
                checklistItem(String(localized: "ee.checkDefineRQ"), isComplete: !ee.researchQuestion.isEmpty)
                checklistItem(String(localized: "ee.checkIdentifySources"), isComplete: ee.status != .planning)
                checklistItem(String(localized: "ee.checkOutlineStructure"), isComplete: ee.status != .planning)
                checklistItem(String(localized: "ee.checkInitialMeeting"), isComplete: !ee.meetingNotes.isEmpty)
            }

            // Initial reflection (RPPF 1)
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "ee.rppfInitial"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.accent)

                TextEditor(text: $rppfInitialText)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.hairline, lineWidth: 1)
                    )

                Text(String(localized: "ee.rppfInitialHint"))
                    .font(.system(size: 11))
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(20)
        .astraCardStyle()
    }

    // MARK: - Research Tab

    private func researchTab(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "ee.researchAnalysis"), icon: .search)

            VStack(alignment: .leading, spacing: 8) {
                checklistItem(String(localized: "ee.checkGatherPrimary"), isComplete: ee.status == .researching || ee.status == .drafting || ee.status == .reviewing || ee.status == .submitted)
                checklistItem(String(localized: "ee.checkCompileSecondary"), isComplete: ee.status == .researching || ee.status == .drafting || ee.status == .reviewing || ee.status == .submitted)
                checklistItem(String(localized: "ee.checkArgumentFramework"), isComplete: ee.status == .drafting || ee.status == .reviewing || ee.status == .submitted)
                checklistItem(String(localized: "ee.checkMidpointReflection"), isComplete: ee.rppfMidterm != nil)
            }

            // Midterm reflection (RPPF 2)
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "ee.rppfMidterm"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.accent)

                TextEditor(text: $rppfMidtermText)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.hairline, lineWidth: 1)
                    )

                Text(String(localized: "ee.rppfMidtermHint"))
                    .font(.system(size: 11))
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(20)
        .astraCardStyle()
    }

    // MARK: - Drafting Tab

    private func draftingTab(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "ee.drafting"), icon: .edit)

            TextEditor(text: $essayContent)
                .font(.system(size: 14))
                .foregroundColor(Color.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 250)
                .padding(12)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.hairline, lineWidth: 1)
                )

            HStack {
                Text(String(format: String(localized: "ee.wordsCount"), essayContent.wordCount, ee.maxWordCount))
                    .font(.astraMono(13, .medium))
                    .foregroundColor(
                        essayContent.wordCount > ee.maxWordCount
                            ? Color.semanticDanger
                            : Color.textSecondary
                    )

                Spacer()

                Button {
                    updateStatus(ee, to: .drafting)
                } label: {
                    HStack(spacing: 6) {
                        AstraIconView(.check, size: 11)
                        Text(String(localized: "ee.saveDraft"))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.accent)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .astraCardStyle()
    }

    // MARK: - Review Tab

    private func reviewTab(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "ee.reviewSubmission"), icon: .visibility)

            VStack(alignment: .leading, spacing: 8) {
                checklistItem(String(localized: "ee.checkProofread"), isComplete: ee.status == .reviewing || ee.status == .submitted)
                checklistItem(String(localized: "ee.checkCitations"), isComplete: ee.status == .reviewing || ee.status == .submitted)
                checklistItem(String(localized: "ee.checkFinalReflection"), isComplete: ee.rppfFinal != nil)
                checklistItem(String(localized: "ee.checkSubmit"), isComplete: ee.status == .submitted)
            }

            // Final reflection (RPPF 3)
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "ee.rppfFinal"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.accent)

                TextEditor(text: $rppfFinalText)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.hairline, lineWidth: 1)
                    )

                Text(String(localized: "ee.rppfFinalHint"))
                    .font(.system(size: 11))
                    .foregroundColor(Color.textSecondary)
            }

            // Submit button
            HStack {
                Spacer()
                Button {
                    updateStatus(ee, to: .submitted)
                } label: {
                    HStack(spacing: 6) {
                        AstraIconView(.send, size: 13)
                        Text(String(localized: "ee.markSubmitted"))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accent)
                    .clipShape(Capsule())
                    .shadow(color: Color.accent.opacity(0.15), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .astraCardStyle()
    }

    // MARK: - RPPF Reflection Section

    private func rppfReflectionSection(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "ee.rppfReflections"), icon: .menuBook)

            HStack(spacing: 12) {
                rppfCard(ee.rppfInitial, title: String(localized: "ee.rppfInitialShort"), icon: .looksOne, color: Color.accent)
                rppfCard(ee.rppfMidterm, title: String(localized: "ee.rppfMidtermShort"), icon: .looksTwo, color: Color.accent.opacity(0.8))
                rppfCard(ee.rppfFinal, title: String(localized: "ee.rppfFinalShort"), icon: .looks_3, color: Color.accent.opacity(0.7))
            }
        }
    }

    private func rppfCard(_ text: String?, title: String, icon: AstraIcon, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                AstraIconView(icon, size: 14)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
            }

            if let text = text, !text.isEmpty {
                Text(text)
                    .font(.system(size: 13))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(4)
            } else {
                HStack(spacing: 6) {
                    AstraIconView(.edit, size: 11)
                        .foregroundColor(Color.textSecondary.opacity(0.4))
                    Text(String(localized: "ee.notYetWritten"))
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .astraCardStyle()
    }

    // MARK: - Meeting Notes Section

    private func meetingNotesSection(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel(String(localized: "ee.meetingNotes"), icon: .group)

                Spacer()

                Button {
                    addMeetingNote(to: ee)
                } label: {
                    HStack(spacing: 4) {
                        AstraIconView(.addCircle, size: 13)
                        Text(String(localized: "ee.addMeeting"))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.surface)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.hairline, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            if ee.meetingNotes.isEmpty {
                VStack(spacing: 8) {
                    AstraIconView(.group, size: 24)
                        .foregroundColor(Color.textSecondary.opacity(0.3))
                    Text(String(localized: "ee.noMeetings"))
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(ee.meetingNotes) { meeting in
                        meetingNoteRow(meeting, isExpanded: expandedMeeting == meeting.id) {
                            withAnimation {
                                expandedMeeting = expandedMeeting == meeting.id ? nil : meeting.id
                            }
                        }
                    }
                }
            }

            // Add meeting form
            VStack(spacing: 8) {
                TextEditor(text: $meetingSummary)
                    .font(.system(size: 13))
                    .foregroundColor(Color.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 60)
                    .padding(10)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.hairline, lineWidth: 1)
                    )

                HStack(spacing: 8) {
                    TextField(String(localized: "ee.actionItemPlaceholder"), text: $meetingActionItem)
                        .font(.system(size: 13))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.surface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.hairline, lineWidth: 1)
                        )

                    Button {
                        newMeetingNotes.append(meetingActionItem)
                        meetingActionItem = ""
                    } label: {
                        AstraIconView(.addCircle, size: 16)
                            .foregroundColor(Color.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .astraCardStyle()
    }

    // MARK: - Word Count Section

    private func wordCountSection(_ ee: ExtendedEssay) -> some View {
        VStack(spacing: 16) {
            HStack {
                sectionLabel(String(localized: "ee.wordCount"), icon: .textFields)

                Spacer()

                Text("\(essayContent.wordCount)")
                    .font(.astraMono(36, .bold))
                    .foregroundColor(
                        essayContent.wordCount > ee.maxWordCount
                            ? Color.semanticDanger
                            : Color.accent
                    )

                Text("/ \(ee.maxWordCount)")
                    .font(.astraMono(18, .regular))
                    .foregroundColor(Color.textSecondary)
            }

            // Progress bar toward max word count
            let ratio = min(1.0, Double(essayContent.wordCount) / Double(max(ee.maxWordCount, 1)))
            progressBar(for: ratio)

            HStack(spacing: 16) {
                Label { Text(String(localized: "ee.minWords")) } icon: { AstraIconView(.arrowDownward, size: 12) }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color.textSecondary)

                Spacer()

                Label { Text(String(format: String(localized: "ee.maxWords"), ee.maxWordCount)) } icon: { AstraIconView(.arrowUpward, size: 12) }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(
                        essayContent.wordCount > ee.maxWordCount
                            ? Color.semanticDanger
                            : Color.textSecondary
                    )
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

    private func progressBar(for progress: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentContainer)
                    .frame(height: 8)

                // Fill with ice-blue gradient
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        Color.accent
                    )
                    .frame(width: geometry.size.width * min(max(progress, 0), 1), height: 8)

                // Glow overlay
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        Color.accent
                    )
                    .frame(width: geometry.size.width * min(max(progress, 0), 1), height: 4)
            }
        }
        .frame(height: 8)
    }

    private func checklistItem(_ label: String, isComplete: Bool) -> some View {
        HStack(spacing: 10) {
            AstraIconView(isComplete ? .checkCircle : .circle, size: 14)
                .foregroundColor(isComplete ? Color.accent : Color.textSecondary.opacity(0.4))

            Text(label)
                .font(.system(size: 13))
                .foregroundColor(isComplete ? Color.textPrimary : Color.textSecondary.opacity(0.6))
                .strikethrough(isComplete, color: Color.textSecondary)
        }
    }

    private func meetingNoteRow(_ meeting: MeetingNote, isExpanded: Bool, toggle: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: toggle) {
                HStack {
                    AstraIconView(isExpanded ? .expandMore : .chevronRight, size: 11)
                        .foregroundColor(Color.accent)

                    Text(meeting.date.shortDateString)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.textPrimary)

                    Spacer()

                    if !meeting.actionItems.isEmpty {
                        Text("^[\(meeting.actionItems.count) action](inflect: true)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(meeting.summary)
                    .font(.system(size: 13))
                    .foregroundColor(Color.textPrimary)
                    .padding(.leading, 20)

                if !meeting.actionItems.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(meeting.actionItems, id: \.self) { item in
                            HStack(spacing: 6) {
                                AstraIconView(.playArrow, size: 9)
                                    .foregroundColor(Color.accent)
                                Text(item)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.textSecondary)
                            }
                            .padding(.leading, 20)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
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

    private func statusColor(_ status: EEStatus) -> Color {
        switch status {
        case .planning:    return Color.semanticWarning
        case .researching: return Color.accent
        case .drafting:    return Color.accent.opacity(0.8)
        case .reviewing:   return Color.accent.opacity(0.7)
        case .submitted:   return Color.semanticSuccess
        }
    }

    // MARK: - Actions

    private func createNewEE() {
        let ee = ExtendedEssay(
            title: String(format: String(localized: "ee.defaultTitle"), essays.count + 1),
            subject: "",
            researchQuestion: "",
            content: "",
            wordCount: 0,
            maxWordCount: 4000,
            supervisor: nil,
            session: "2026"
        )
        modelContext.insert(ee)
        selectedEE = ee
        loadEE(ee)
    }

    private func loadEE(_ ee: ExtendedEssay) {
        researchQuestion = ee.researchQuestion
        rppfInitialText = ee.rppfInitial ?? ""
        rppfMidtermText = ee.rppfMidterm ?? ""
        rppfFinalText = ee.rppfFinal ?? ""
        essayContent = ee.content
    }

    private func saveEE(_ ee: ExtendedEssay) {
        ee.researchQuestion = researchQuestion
        ee.rppfInitial = rppfInitialText.isEmpty ? nil : rppfInitialText
        ee.rppfMidterm = rppfMidtermText.isEmpty ? nil : rppfMidtermText
        ee.rppfFinal = rppfFinalText.isEmpty ? nil : rppfFinalText
        ee.content = essayContent
        ee.wordCount = essayContent.wordCount
    }

    private func updateStatus(_ ee: ExtendedEssay, to status: EEStatus) {
        saveEE(ee)
        ee.status = status
    }

    private func addMeetingNote(to ee: ExtendedEssay) {
        let note = MeetingNote(
            date: Date(),
            summary: meetingSummary,
            actionItems: newMeetingNotes
        )
        ee.meetingNotes.append(note)
        meetingSummary = ""
        meetingActionItem = ""
        newMeetingNotes = []
    }
}

// MARK: - EE Section Tab

enum EESectionTab: String, CaseIterable, Identifiable {
    case exploration
    case research
    case drafting
    case review

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .exploration: return String(localized: "ee.tabExploration")
        case .research:    return String(localized: "ee.tabResearch")
        case .drafting:    return String(localized: "ee.tabDrafting")
        case .review:      return String(localized: "ee.tabReview")
        }
    }

    var astraIcon: AstraIcon {
        switch self {
        case .exploration: return .lightbulb
        case .research:    return .search
        case .drafting:    return .edit
        case .review:      return .visibility
        }
    }
}

// MARK: - Preview

#Preview {
    EETrackerView()
        
        .modelContainer(for: ExtendedEssay.self, inMemory: true)
}
