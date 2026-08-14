// EETrackerView.swift — AstraNotes
// Extended Essay progress tracker with ice-blue gradient progress bars,
// RPPF reflection cards, meeting notes, and word count display
// using JetBrains Mono. Designed with the Soft Cryo aesthetic.

import SwiftUI
import SwiftData

// MARK: - EE Tracker View

struct EETrackerView: View {

    // MARK: - Environment

    @Environment(\.themeManager) private var tm
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
        .background(CryoColors.background(tm))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("graduationcap")
                    .font(.system(size: 22))
                    .foregroundStyle(CryoColors.accent(tm))
                Text(String(localized: "ee.title"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(CryoColors.foreground(tm))
            }

            Text(String(localized: "ee.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(CryoColors.foregroundMuted(tm))

            HStack {
                Spacer()
                Text("^[\(essays.count) essay](inflect: true)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm))

                Button {
                    createNewEE()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text(String(localized: "ee.newEssay"))
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

    // MARK: - EE Selection (no EE selected)

    private var eeSelectionSection: some View {
        VStack(spacing: 16) {
            if essays.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "graduationcap")
                        .font(.system(size: 40))
                        .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.3))
                    Text(String(localized: "ee.noEssays"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(CryoColors.foreground(tm))
                    Text(String(localized: "ee.noEssaysHint"))
                        .font(.system(size: 13))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
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
                    .foregroundColor(CryoColors.foreground(tm))

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
                    .foregroundColor(CryoColors.accent(tm))
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                Label(ee.subject, systemImage: "book")
                    .font(.system(size: 12))
                    .foregroundColor(CryoColors.foregroundMuted(tm))

                if let supervisor = ee.supervisor, !supervisor.isEmpty {
                    Label(supervisor, systemImage: "person")
                        .font(.system(size: 12))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                }

                Spacer()

                Text("\(ee.wordCount) / \(ee.maxWordCount)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced, family: "JetBrains Mono"))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
            }

            // Progress bar
            progressBar(for: ee.progress)
        }
        .padding(16)
        .cryoCardStyle(tm)
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
                    Image(systemName: "arrow.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text(String(localized: "ee.backToAllEssays"))
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

    // MARK: - Research Question Card

    private func researchQuestionCard(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(CryoColors.accent(tm))
                Text(String(localized: "ee.researchQuestion"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(CryoColors.foreground(tm))
            }

            TextEditor(text: $researchQuestion)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(CryoColors.foreground(tm))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 48)
                .padding(12)
                .background(CryoColors.backgroundWarm(tm))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CryoColors.border(tm), lineWidth: 1)
                )

            // Subject + supervisor badges
            HStack(spacing: 8) {
                if !ee.subject.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "book")
                            .font(.system(size: 10))
                        Text(ee.subject)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(CryoColors.accentDark(tm))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(CryoColors.accentGlow(tm))
                    .clipShape(Capsule())
                }

                if let supervisor = ee.supervisor, !supervisor.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person")
                            .font(.system(size: 10))
                        Text(supervisor)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(CryoColors.foregroundMuted(tm))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(CryoColors.frost(tm))
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
        .cryoCardStyle(tm)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(CryoColors.crystalBorderGradient(tm), lineWidth: 2)
        )
    }

    // MARK: - Progress Bar Section

    private func progressBarSection(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(localized: "ee.overallProgress"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(CryoColors.foreground(tm))

                Spacer()

                Text("\(Int(ee.progress * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .monospaced, family: "JetBrains Mono"))
                    .foregroundColor(CryoColors.accent(tm))
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
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(tab.displayName)
                            .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                    }
                    .foregroundColor(selectedTab == tab ? .white : CryoColors.foreground(tm))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab
                            ? CryoColors.primaryGradient(tm)
                            : CryoColors.backgroundWarm(tm)
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                selectedTab == tab
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
            sectionLabel(String(localized: "ee.explorationPlanning"), icon: "lightbulb")

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
                    .foregroundColor(CryoColors.accent(tm))

                TextEditor(text: $rppfInitialText)
                    .font(.system(size: 14))
                    .foregroundColor(CryoColors.foreground(tm))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(CryoColors.backgroundWarm(tm))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CryoColors.border(tm), lineWidth: 1)
                    )

                Text(String(localized: "ee.rppfInitialHint"))
                    .font(.system(size: 11))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
            }
        }
        .padding(20)
        .cryoCardStyle(tm)
    }

    // MARK: - Research Tab

    private func researchTab(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "ee.researchAnalysis"), icon: "magnifyingglass")

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
                    .foregroundColor(CryoColors.accent(tm))

                TextEditor(text: $rppfMidtermText)
                    .font(.system(size: 14))
                    .foregroundColor(CryoColors.foreground(tm))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(CryoColors.backgroundWarm(tm))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CryoColors.border(tm), lineWidth: 1)
                    )

                Text(String(localized: "ee.rppfMidtermHint"))
                    .font(.system(size: 11))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
            }
        }
        .padding(20)
        .cryoCardStyle(tm)
    }

    // MARK: - Drafting Tab

    private func draftingTab(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "ee.drafting"), icon: "pencil")

            TextEditor(text: $essayContent)
                .font(.system(size: 14))
                .foregroundColor(CryoColors.foreground(tm))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 250)
                .padding(12)
                .background(CryoColors.backgroundWarm(tm))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CryoColors.border(tm), lineWidth: 1)
                )

            HStack {
                Text(String(localized: "ee.wordsCount \(essayContent.wordCount) \(ee.maxWordCount)"))
                    .font(.system(size: 13, weight: .medium, design: .monospaced, family: "JetBrains Mono"))
                    .foregroundColor(
                        essayContent.wordCount > ee.maxWordCount
                            ? CryoColors.error(tm)
                            : CryoColors.foregroundMuted(tm)
                    )

                Spacer()

                Button {
                    updateStatus(ee, to: .drafting)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                        Text(String(localized: "ee.saveDraft"))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(CryoColors.primaryGradient(tm))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .cryoCardStyle(tm)
    }

    // MARK: - Review Tab

    private func reviewTab(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "ee.reviewSubmission"), icon: "eye")

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
                    .foregroundColor(CryoColors.accent(tm))

                TextEditor(text: $rppfFinalText)
                    .font(.system(size: 14))
                    .foregroundColor(CryoColors.foreground(tm))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(CryoColors.backgroundWarm(tm))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CryoColors.border(tm), lineWidth: 1)
                    )

                Text(String(localized: "ee.rppfFinalHint"))
                    .font(.system(size: 11))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
            }

            // Submit button
            HStack {
                Spacer()
                Button {
                    updateStatus(ee, to: .submitted)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane")
                            .font(.system(size: 13, weight: .semibold))
                        Text(String(localized: "ee.markSubmitted"))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(CryoColors.primaryGradient(tm))
                    .clipShape(Capsule())
                    .shadow(color: CryoColors.shadowGlow(tm), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .cryoCardStyle(tm)
    }

    // MARK: - RPPF Reflection Section

    private func rppfReflectionSection(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "ee.rppfReflections"), icon: "text.book.closed")

            HStack(spacing: 12) {
                rppfCard(ee.rppfInitial, title: String(localized: "ee.rppfInitialShort"), icon: "1.circle", color: CryoColors.accent(tm))
                rppfCard(ee.rppfMidterm, title: String(localized: "ee.rppfMidtermShort"), icon: "2.circle", color: CryoColors.accentLight(tm))
                rppfCard(ee.rppfFinal, title: String(localized: "ee.rppfFinalShort"), icon: "3.circle", color: CryoColors.crystal(tm))
            }
        }
    }

    private func rppfCard(_ text: String?, title: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(CryoColors.foreground(tm))
            }

            if let text = text, !text.isEmpty {
                Text(text)
                    .font(.system(size: 13))
                    .foregroundColor(CryoColors.foreground(tm))
                    .lineLimit(4)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 11))
                        .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.4))
                    Text(String(localized: "ee.notYetWritten"))
                        .font(.system(size: 12))
                        .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .cryoCardStyle(tm)
    }

    // MARK: - Meeting Notes Section

    private func meetingNotesSection(_ ee: ExtendedEssay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel(String(localized: "ee.meetingNotes"), icon: "person.2")

                Spacer()

                Button {
                    addMeetingNote(to: ee)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 13))
                        Text(String(localized: "ee.addMeeting"))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(CryoColors.accentDark(tm))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(CryoColors.backgroundWarm(tm))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(CryoColors.border(tm), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            if ee.meetingNotes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.2")
                        .font(.system(size: 24))
                        .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.3))
                    Text(String(localized: "ee.noMeetings"))
                        .font(.system(size: 13))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
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
                    .foregroundColor(CryoColors.foreground(tm))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 60)
                    .padding(10)
                    .background(CryoColors.backgroundWarm(tm))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(CryoColors.border(tm), lineWidth: 1)
                    )

                HStack(spacing: 8) {
                    TextField(String(localized: "ee.actionItemPlaceholder"), text: $meetingActionItem)
                        .font(.system(size: 13))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(CryoColors.backgroundWarm(tm))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(CryoColors.border(tm), lineWidth: 1)
                        )

                    Button {
                        newMeetingNotes.append(meetingActionItem)
                        meetingActionItem = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(CryoColors.accent(tm))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .cryoCardStyle(tm)
    }

    // MARK: - Word Count Section

    private func wordCountSection(_ ee: ExtendedEssay) -> some View {
        VStack(spacing: 16) {
            HStack {
                sectionLabel(String(localized: "ee.wordCount"), icon: "textformat")

                Spacer()

                Text("\(essayContent.wordCount)")
                    .font(.system(size: 36, weight: .bold, design: .monospaced, family: "JetBrains Mono"))
                    .foregroundColor(
                        essayContent.wordCount > ee.maxWordCount
                            ? CryoColors.error(tm)
                            : CryoColors.accent(tm)
                    )

                Text("/ \(ee.maxWordCount)")
                    .font(.system(size: 18, weight: .regular, design: .monospaced, family: "JetBrains Mono"))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
            }

            // Progress bar toward max word count
            let ratio = min(1.0, Double(essayContent.wordCount) / Double(max(ee.maxWordCount, 1)))
            progressBar(for: ratio)

            HStack(spacing: 16) {
                Label(String(localized: "ee.minWords"), systemImage: "arrow.down.to.line")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm))

                Spacer()

                Label(String(localized: "ee.maxWords \(ee.maxWordCount)"), systemImage: "arrow.up.to.line")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(
                        essayContent.wordCount > ee.maxWordCount
                            ? CryoColors.error(tm)
                            : CryoColors.foregroundMuted(tm)
                    )
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

    private func progressBar(for progress: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(CryoColors.frost(tm))
                    .frame(height: 8)

                // Fill with ice-blue gradient
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [CryoColors.accent(tm), CryoColors.accentDark(tm)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * min(max(progress, 0), 1), height: 8)

                // Glow overlay
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [CryoColors.accentLight(tm).opacity(0.6), CryoColors.accent(tm).opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * min(max(progress, 0), 1), height: 4)
            }
        }
        .frame(height: 8)
    }

    private func checklistItem(_ label: String, isComplete: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(isComplete ? CryoColors.accent(tm) : CryoColors.foregroundMuted(tm).opacity(0.4))

            Text(label)
                .font(.system(size: 13))
                .foregroundColor(isComplete ? CryoColors.foreground(tm) : CryoColors.foregroundMuted(tm).opacity(0.6))
                .strikethrough(isComplete, color: CryoColors.foregroundMuted(tm))
        }
    }

    private func meetingNoteRow(_ meeting: MeetingNote, isExpanded: Bool, toggle: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: toggle) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(CryoColors.accent(tm))

                    Text(meeting.date.shortDateString)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(CryoColors.foreground(tm))

                    Spacer()

                    if !meeting.actionItems.isEmpty {
                        Text("^[\(meeting.actionItems.count) action](inflect: true)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(CryoColors.foregroundMuted(tm))
                    }
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(meeting.summary)
                    .font(.system(size: 13))
                    .foregroundColor(CryoColors.foreground(tm))
                    .padding(.leading, 20)

                if !meeting.actionItems.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(meeting.actionItems, id: \.self) { item in
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.right")
                                    .font(.system(size: 9))
                                    .foregroundColor(CryoColors.accent(tm))
                                Text(item)
                                    .font(.system(size: 12))
                                    .foregroundColor(CryoColors.foregroundMuted(tm))
                            }
                            .padding(.leading, 20)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
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

    private func statusColor(_ status: EEStatus) -> Color {
        switch status {
        case .planning:    return CryoColors.warning(tm)
        case .researching: return CryoColors.accent(tm)
        case .drafting:    return CryoColors.accentLight(tm)
        case .reviewing:   return CryoColors.crystal(tm)
        case .submitted:   return CryoColors.success(tm)
        }
    }

    // MARK: - Actions

    private func createNewEE() {
        let ee = ExtendedEssay(
            title: String(localized: "ee.defaultTitle \(essays.count + 1)"),
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

    var icon: String {
        switch self {
        case .exploration: return "lightbulb"
        case .research:    return "magnifyingglass"
        case .drafting:    return "pencil"
        case .review:      return "eye"
        }
    }
}

// MARK: - Preview

#Preview {
    EETrackerView()
        .environment(ThemeManager())
        .modelContainer(for: ExtendedEssay.self, inMemory: true)
}
