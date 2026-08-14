import SwiftUI
import SwiftData

// MARK: - DashboardView
// Main dashboard with the Astra bento layout (asymmetric 2fr/1fr grid):
// a hero recording cell, a Today column, recent activity list,
// number cells, and an IB progress strip. Four distinct cell families,
// no repeated equal-card rows.

struct DashboardView: View {
    /// Allows quick actions to navigate the sidebar.
    var onNavigate: ((NavigationDestination) -> Void)?

    @Query private var recordings: [RecordingSession]
    @Query private var notes: [GeneratedNote]
    @Query private var flashcards: [Flashcard]
    @Query private var subjects: [Subject]
    @Query private var essays: [ExtendedEssay]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                welcomeSection

                // Row 1: hero + Today column (asymmetric)
                HStack(alignment: .top, spacing: Spacing.xl) {
                    heroCell
                        .frame(maxWidth: .infinity)
                    todayCell
                        .frame(width: 240)
                }

                // Row 2: recent activity + number cells
                HStack(alignment: .top, spacing: Spacing.xl) {
                    recentActivitySection
                        .frame(maxWidth: .infinity)
                    numberColumn
                        .frame(width: 240)
                }

                // Row 3: IB progress strip
                ibProgressSection
            }
            .padding(Spacing.xxl)
        }
        .background(Color.surfaceBackground)
    }

    // MARK: - Welcome Section

    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "dashboard.welcome"))
                .font(TypeScale.body)
                .foregroundStyle(.textSecondary)
            Text(String(localized: "dashboard.title"))
                .font(TypeScale.display)
                .foregroundStyle(.textPrimary)
        }
    }

    // MARK: - Hero Cell

    private var heroCell: some View {
        AstraCard(tint: Color.accent.opacity(0.06)) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack(spacing: Spacing.sm) {
                    AstraAdornment(icon: .mic, tint: .accent)
                    Text(String(localized: "dashboard.startRecording"))
                        .font(TypeScale.heading)
                        .foregroundStyle(.textPrimary)
                    Spacer()
                    if let last = recordings.sorted(by: { $0.date > $1.date }).first {
                        Text(last.formattedDuration)
                            .font(.astraMono(11))
                            .foregroundStyle(.textTertiary)
                    }
                }

                // Real waveform from the most recent recording
                if let last = recordings.sorted(by: { $0.date > $1.date }).first,
                   !last.waveformData.isEmpty {
                    StaticWaveform(levels: last.waveformData.map(Double.init))
                } else {
                    RoundedRectangle(cornerRadius: Radius.card)
                        .fill(Color.accent.opacity(0.08))
                        .frame(height: 40)
                        .overlay(
                            AstraIconView(.graphicEq, size: 20)
                                .foregroundStyle(Color.accent.opacity(0.6))
                        )
                }

                HStack(spacing: Spacing.md) {
                    AstraButton(
                        title: String(localized: "dashboard.startRecording"),
                        icon: .mic,
                        style: .primary
                    ) {
                        onNavigate?(.recording)
                    }
                    AstraButton(
                        title: String(localized: "dashboard.generateNotes"),
                        style: .secondary
                    ) {
                        onNavigate?(.notes)
                    }
                }
            }
        }
    }

    // MARK: - Today Cell

    private var todayCell: some View {
        AstraCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: String(localized: "dashboard.dueCards"), icon: .schedule)

                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text("\(flashcards.filter(\.isDue).count)")
                        .font(.astraMono(28, .semibold))
                        .foregroundStyle(.textPrimary)
                    Text(String(localized: "dashboard.dueCards"))
                        .font(TypeScale.caption)
                        .foregroundStyle(.textSecondary)
                }

                Divider().overlay(Color.hairline)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    miniStat(
                        icon: .style,
                        value: "\(flashcards.count)",
                        label: String(localized: "dashboard.flashcards")
                    )
                    miniStat(
                        icon: .star,
                        value: "\(subjects.filter { $0.level == IBLevel.hl.rawValue }.count)",
                        label: String(localized: "dashboard.hlSubjects")
                    )
                }
            }
        }
    }

    private func miniStat(icon: AstraIcon, value: String, label: String) -> some View {
        HStack(spacing: Spacing.sm) {
            AstraIconView(icon, size: 12)
                .foregroundStyle(Color.accent)
                .frame(width: 22)
            Text(value)
                .font(.astraMono(14, .semibold))
                .foregroundStyle(.textPrimary)
            Text(label)
                .font(TypeScale.caption)
                .foregroundStyle(.textSecondary)
            Spacer()
        }
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(
                title: String(localized: "dashboard.recentActivity"),
                icon: .history
            )

            if recordings.isEmpty {
                EmptyStateView(
                    icon: .mic,
                    title: String(localized: "dashboard.noActivity"),
                    message: String(localized: "dashboard.noActivityHint"),
                    ctaTitle: String(localized: "dashboard.startRecording")
                ) {
                    onNavigate?(.recording)
                }
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card)
                        .stroke(Color.hairline, lineWidth: 1)
                )
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(Array(recordings.sorted(by: { $0.date > $1.date }).prefix(5))) { recording in
                        NoteCell(
                            title: recording.title,
                            group: subjectGroup(for: recording.subjectName),
                            subjectIcon: subjectIcon(for: recording.subjectName),
                            subjectName: recording.subjectName ?? String(localized: "recording.noSubject"),
                            dateText: recording.date.shortDateString,
                            durationText: recording.formattedDuration
                        ) {
                            onNavigate?(.transcription)
                        }
                    }
                }
                .padding(Spacing.sm)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card)
                        .stroke(Color.hairline, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Number Column

    private var numberColumn: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: String(localized: "dashboard.subjects"), icon: .menuBook)

            AstraCard {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text("\(subjects.count)")
                        .font(.astraMono(28, .semibold))
                        .foregroundStyle(.textPrimary)
                    Text(String(localized: "dashboard.subjects"))
                        .font(TypeScale.caption)
                        .foregroundStyle(.textSecondary)
                    Spacer()
                }
            }

            AstraCard {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text("\(notes.count)")
                        .font(.astraMono(28, .semibold))
                        .foregroundStyle(.textPrimary)
                    Text(String(localized: "dashboard.notes"))
                        .font(TypeScale.caption)
                        .foregroundStyle(.textSecondary)
                    Spacer()
                }
            }

            AstraCard {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text("\(recordings.count)")
                        .font(.astraMono(28, .semibold))
                        .foregroundStyle(.textPrimary)
                    Text(String(localized: "dashboard.recordings"))
                        .font(TypeScale.caption)
                        .foregroundStyle(.textSecondary)
                    Spacer()
                }
            }
        }
    }

    // MARK: - IB Progress Strip

    private var ibProgressSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: String(localized: "sidebar.ibCore"), icon: .school)

            HStack(spacing: Spacing.md) {
                progressCell(
                    label: String(localized: "nav.extendedEssay"),
                    detail: essays.isEmpty
                        ? "0 / 4000"
                        : "\(essays.reduce(0) { $0 + $1.wordCount }) / \(essays.first?.maxWordCount ?? 4000)",
                    progress: essays.first?.progress ?? 0
                )
                progressCell(
                    label: String(localized: "nav.internalAssessment"),
                    detail: "",
                    progress: 0
                )
                progressCell(
                    label: String(localized: "nav.tok"),
                    detail: "",
                    progress: 0
                )
            }
        }
    }

    private func progressCell(label: String, detail: String, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(label)
                    .font(TypeScale.subheading)
                    .foregroundStyle(.textPrimary)
                Spacer()
                if !detail.isEmpty {
                    Text(detail)
                        .font(.astraMono(11))
                        .foregroundStyle(.textTertiary)
                }
            }
            ProgressHairline(progress: progress)
        }
        .padding(Layout.cardPadding)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(Color.hairline, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func subjectGroup(for name: String?) -> Int {
        guard let name else { return 0 }
        return subjects.first(where: { $0.name == name })?.ibGroup ?? 0
    }

    private func subjectIcon(for name: String?) -> AstraIcon {
        guard let name else { return .graphicEq }
        return subjects.first(where: { $0.name == name })?.group.astraIcon ?? .graphicEq
    }
}
