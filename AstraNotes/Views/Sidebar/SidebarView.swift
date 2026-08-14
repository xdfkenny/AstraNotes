import SwiftUI
import SwiftData

// MARK: - SidebarView
// The primary navigation sidebar with a 240pt fixed width. Displays the
// app header, main navigation sections, user-created subjects (from
// SwiftData), IB Core shortcuts, and a settings link. The selected
// destination is shown with a left-side accent indicator bar and a
// tinted background highlight.

struct SidebarView: View {
    @Environment(\.themeManager) private var tm
    @Binding var selectedDestination: NavigationDestination
    @Query private var subjects: [Subject]

    var body: some View {
        VStack(spacing: 0) {
            // App header
            appHeader
                .padding(.bottom, 8)

            Divider()
                .background(CryoColors.border(tm))
                .padding(.horizontal, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 4) {
                    // Main navigation
                    mainNavigationSection

                    sidebarDivider

                    // Subjects section
                    subjectsSection

                    sidebarDivider

                    // IB Core section
                    ibCoreSection

                    sidebarDivider

                    // Bottom settings
                    settingsSection
                }
                .padding(.vertical, 8)
            }
        }
        .frame(minWidth: 200, idealWidth: 240, maxWidth: 280)
        .background(CryoColors.backgroundWarm(tm))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .background(CryoColors.border(tm))
                .frame(maxWidth: .infinity, alignment: .trailing)
        )
    }

    // MARK: - Section Dividers

    private var sidebarDivider: some View {
        Divider()
            .background(CryoColors.border(tm))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
    }

    // MARK: - App Header

    private var appHeader: some View {
        HStack(spacing: 8) {
            Text("\u{2744}\u{FE0F}")
                .font(.system(size: 20))
            Text(String(localized: "app.name"))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(CryoColors.foreground(tm))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Main Navigation Section

    private var mainNavigationSection: some View {
        VStack(spacing: 2) {
            sidebarItem(String(localized: "nav.dashboard"), icon: "square.grid.2x2", destination: .dashboard)
            sidebarItem(String(localized: "nav.recording"), icon: "mic.circle", destination: .recording)
            sidebarItem(String(localized: "nav.transcription"), icon: "text.document", destination: .transcription)
            sidebarItem(String(localized: "nav.notes"), icon: "doc.text", destination: .notes)
            sidebarItem(String(localized: "nav.flashcards"), icon: "square.stack", destination: .flashcards)
            sidebarItem(String(localized: "nav.quiz"), icon: "questionmark.circle", destination: .quiz)
            sidebarItem(String(localized: "nav.studyGuide"), icon: "book", destination: .studyGuide)
        }
    }

    // MARK: - Subjects Section

    private var subjectsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader(String(localized: "sidebar.subjects"))

            if subjects.isEmpty {
                Text(String(localized: "nav.noSubjects"))
                    .font(.system(size: 12))
                    .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.5))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
            } else {
                ForEach(subjects) { subject in
                    subjectRow(subject)
                }
            }
        }
    }

    // MARK: - IB Core Section

    private var ibCoreSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader(String(localized: "sidebar.ibCore"))
            sidebarItem(String(localized: "nav.tok"), icon: "brain", destination: .tok)
            sidebarItem(String(localized: "nav.extendedEssay"), icon: "graduationcap", destination: .ee)
            sidebarItem(String(localized: "nav.internalAssessment"), icon: "chart.bar", destination: .ia)
            sidebarItem(String(localized: "nav.cas"), icon: "heart.circle", destination: .cas)
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        sidebarItem(String(localized: "nav.settings"), icon: "gearshape", destination: .settings)
    }

    // MARK: - Reusable Components

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(CryoColors.foregroundMuted(tm))
            .textCase(.uppercase)
            .tracking(0.05)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
    }

    private func sidebarItem(
        _ title: String,
        icon: String,
        destination: NavigationDestination
    ) -> some View {
        let isSelected = selectedDestination == destination

        return Button {
            selectedDestination = destination
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? CryoColors.accent(tm) : CryoColors.foregroundMuted(tm))
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? CryoColors.accent(tm) : CryoColors.foreground(tm))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? CryoColors.accent(tm).opacity(0.1)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .leading) {
                if isSelected {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(CryoColors.accent(tm))
                        .frame(width: 3, height: 20)
                        .padding(.leading, -1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func subjectRow(_ subject: Subject) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: subject.colorHex))
                .frame(width: 8, height: 8)

            Text(subject.name)
                .font(.system(size: 12))
                .foregroundColor(CryoColors.foreground(tm))
                .lineLimit(1)

            Spacer()

            Text(subject.level.shortName)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(CryoColors.foregroundMuted(tm))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}
