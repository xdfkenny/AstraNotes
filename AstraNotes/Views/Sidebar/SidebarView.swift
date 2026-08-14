import SwiftUI
import SwiftData

// MARK: - SidebarView
// Primary navigation sidebar (240pt) with the Astra design system:
// grouped sections (Studio / Library / Study / IB Core), subject rows
// with group roundels, a semantic status footer, and settings access.

struct SidebarView: View {
    @Binding var selectedDestination: NavigationDestination
    @Query private var subjects: [Subject]
    @Query private var recordings: [RecordingSession]
    @Query private var flashcards: [Flashcard]
    @Query private var essays: [ExtendedEssay]
    @Query private var casEntries: [CASEntry]
    @Query private var settings: [AppSettings]

    var body: some View {
        VStack(spacing: 0) {
            appHeader

            Divider()
                .overlay(Color.hairline)
                .padding(.horizontal, Spacing.md)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    studioSection
                    librarySection
                    studySection
                    ibCoreSection
                }
                .padding(.vertical, Spacing.md)
            }

            Divider()
                .overlay(Color.hairline)

            statusFooter
        }
        .frame(minWidth: 200, idealWidth: LayoutTokens.sidebarWidth, maxWidth: 280)
        .background(Color.surfaceBackground)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.hairline)
                .frame(width: 1)
        }
    }

    // MARK: - App Header

    private var appHeader: some View {
        HStack(spacing: Spacing.sm) {
            AstraIconView(.autoAwesome, size: 14)
                .foregroundStyle(Color.accent)
                .frame(width: 26, height: 26)
                .background(Color.accentContainer)
                .clipShape(RoundedRectangle(cornerRadius: Radius.micro))
            Text(String(localized: "app.name"))
                .font(.astraDisplay(16, .semibold))
                .foregroundStyle(.textPrimary)
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Studio Section

    private var studioSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            MicroLabel(text: String(localized: "sidebar.studio"))
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xs)
            sidebarItem(.dashboard, icon: .gridView)
            sidebarItem(.recording, icon: .mic)
            sidebarItem(.transcription, icon: .description)
            sidebarItem(.notes, icon: .description)
        }
    }

    // MARK: - Library Section

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 2) {
            MicroLabel(text: String(localized: "sidebar.subjects"))
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xs)

            if subjects.isEmpty {
                Text(String(localized: "nav.noSubjects"))
                    .font(TypeScale.caption)
                    .foregroundStyle(.textTertiary)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.xs)
            } else {
                ForEach(subjects.sorted { $0.sortOrder < $1.sortOrder }) { subject in
                    subjectRow(subject)
                }
            }
        }
    }

    // MARK: - Study Section

    private var studySection: some View {
        VStack(alignment: .leading, spacing: 2) {
            MicroLabel(text: String(localized: "sidebar.study"))
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xs)
            sidebarItem(.flashcards, icon: .style, countChip: dueCardCount)
            sidebarItem(.quiz, icon: .help)
            sidebarItem(.studyGuide, icon: .menuBook)
        }
    }

    // MARK: - IB Core Section

    private var ibCoreSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            MicroLabel(text: String(localized: "sidebar.ibCore"))
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xs)
            sidebarItem(.tok, icon: .psychology)
            sidebarItem(.ee, icon: .school, countChip: essayWordCountText)
            sidebarItem(.ia, icon: .barChart)
            sidebarItem(.cas, icon: .favorite, countChip: casHoursText)
        }
    }

    // MARK: - Status Footer

    private var statusFooter: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                StatusDot(kind: .ready, label: String(localized: "sidebar.whisperReady"))
                Spacer()
                Button {
                    selectedDestination = .settings
                } label: {
                    AstraIconView(.settings, size: 12)
                        .foregroundStyle(.textTertiary)
                        .frame(width: 24, height: 24)
                        .background(Color.hairline.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(String(localized: "nav.settings"))
            }
            HStack(spacing: Spacing.sm) {
                StatusDot(
                    kind: hasDeepSeekKey ? .ready : .idle,
                    label: hasDeepSeekKey
                        ? String(localized: "sidebar.deepSeekConnected")
                        : String(localized: "sidebar.deepSeekNotConfigured")
                )
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Computed

    private var hasDeepSeekKey: Bool {
        settings.first?.hasDeepSeekKey ?? false
    }

    private var dueCardCount: Int {
        flashcards.filter(\.isDue).count
    }

    private var essayWordCountText: String {
        let total = essays.reduce(0) { $0 + $1.wordCount }
        guard total > 0 else { return "" }
        return total >= 1000 ? String(format: "%.1fK", Double(total) / 1000) : "\(total)"
    }

    private var casHoursText: String {
        let total = casEntries.reduce(0.0) { $0 + $1.hoursSpent }
        guard total > 0 else { return "" }
        return String(format: "%.0fh", total)
    }

    // MARK: - Sidebar Item

    private func sidebarItem(
        _ destination: NavigationDestination,
        icon: AstraIcon,
        countChip: String = ""
    ) -> some View {
        let isSelected = selectedDestination == destination

        return Button {
            selectedDestination = destination
        } label: {
            HStack(spacing: Spacing.sm) {
                AstraIconView(icon, size: 13)
                    .foregroundStyle(isSelected ? Color.accent : Color.textTertiary)
                    .frame(width: 18)

                Text(destination.displayName)
                    .font(.astraBody(13, isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.accent : Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                if !countChip.isEmpty {
                    Text(countChip)
                        .font(.astraMono(10, .medium))
                        .foregroundStyle(.textTertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.hairline.opacity(0.5))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 28)
            .background(isSelected ? Color.accentContainer : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Radius.control))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.sm)
        .overlay(alignment: .leading) {
            if isSelected {
                Rectangle()
                    .fill(Color.accent)
                    .frame(width: 3, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 1.5))
                    .padding(.leading, 2)
            }
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Subject Row

    private func subjectRow(_ subject: Subject) -> some View {
        HStack(spacing: Spacing.sm) {
            SubjectRoundel(icon: subject.group.astraIcon, group: subject.ibGroup)

            Text(subject.name)
                .font(TypeScale.body)
                .foregroundStyle(.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 4)

            LevelBadge(level: subject.level)

            let count = recordings.filter { $0.subjectName == subject.name }.count
            if count > 0 {
                Text("\(count)")
                    .font(.astraMono(10, .medium))
                    .foregroundStyle(.textTertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 34)
        .contentShape(Rectangle())
    }
}
