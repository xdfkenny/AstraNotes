import SwiftUI
import SwiftData

// MARK: - DashboardView
// The main dashboard displaying a welcome header, a 3-column statistics
// grid (recordings, notes, flashcards, subjects, due cards, HL subjects),
// recent activity list, and quick-action buttons. All styled with the
// Soft Cryo aesthetic using CryoCard and CryoButton components.

struct DashboardView: View {
    @Environment(\.themeManager) private var tm
    @Query private var recordings: [RecordingSession]
    @Query private var notes: [GeneratedNote]
    @Query private var flashcards: [Flashcard]
    @Query private var subjects: [Subject]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Welcome header
                welcomeSection

                // Stats grid
                statsGrid

                // Recent activity
                recentActivitySection

                // Quick actions
                quickActionsSection
            }
            .padding(32)
        }
        .background(CryoColors.background(tm))
    }

    // MARK: - Welcome Section

    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("\u{2744}\u{FE0F}")
                    .font(.system(size: 32))
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "dashboard.welcome"))
                        .font(.system(size: 14))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                    Text(String(localized: "dashboard.title"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(CryoColors.foreground(tm))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 16
        ) {
            statCard(
                String(localized: "dashboard.recordings"),
                value: "\(recordings.count)",
                icon: "mic.circle",
                color: Color(hex: "#7EC8E3")
            )
            statCard(
                String(localized: "dashboard.notes"),
                value: "\(notes.count)",
                icon: "doc.text",
                color: Color(hex: "#A8D8EA")
            )
            statCard(
                String(localized: "dashboard.flashcards"),
                value: "\(flashcards.count)",
                icon: "square.stack",
                color: Color(hex: "#4A9ECF")
            )
            statCard(
                String(localized: "dashboard.subjects"),
                value: "\(subjects.count)",
                icon: "book",
                color: Color(hex: "#B8E3F5")
            )
            statCard(
                String(localized: "dashboard.dueCards"),
                value: "\(flashcards.filter(\.isDue).count)",
                icon: "clock",
                color: Color(hex: "#E8D5E0")
            )
            statCard(
                String(localized: "dashboard.hlSubjects"),
                value: "\(subjects.filter { $0.level == .hl }.count)",
                icon: "star",
                color: Color(hex: "#C4A8B8")
            )
        }
    }

    private func statCard(
        _ title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        CryoCard(manager: tm, style: .status, padding: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(CryoColors.foreground(tm))
                    Text(title)
                        .font(.system(size: 11))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                }

                Spacer()
            }
        }
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "dashboard.recentActivity"))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(CryoColors.foreground(tm))

            if recordings.isEmpty {
                CryoCard(manager: tm, style: .standard) {
                    VStack(spacing: 12) {
                        Image(systemName: "snowflake")
                            .font(.system(size: 32))
                            .foregroundColor(CryoColors.accent(tm).opacity(0.3))
                        Text(String(localized: "dashboard.noActivity"))
                            .font(.system(size: 14))
                            .foregroundColor(CryoColors.foregroundMuted(tm))
                        Text(String(localized: "dashboard.noActivityHint"))
                            .font(.system(size: 12))
                            .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(32)
                }
            } else {
                ForEach(Array(recordings.sorted(by: { $0.date > $1.date }).prefix(5))) { recording in
                    CryoCard(manager: tm, style: .standard, padding: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "mic.circle")
                                .foregroundColor(CryoColors.accent(tm))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(recording.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(CryoColors.foreground(tm))
                                Text(recording.displayDate)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(CryoColors.foregroundMuted(tm))
                            }
                            Spacer()
                            Text(recording.formattedDuration)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(CryoColors.foregroundMuted(tm))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "dashboard.quickActions"))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(CryoColors.foreground(tm))

            HStack(spacing: 12) {
                CryoButton("\u{1F399}\u{FE0F} \(String(localized: "dashboard.startRecording"))", style: .primary, action: {})
                CryoButton("\u{1F4DD} \(String(localized: "dashboard.generateNotes"))", style: .secondary, action: {})
                CryoButton("\u{1F0CF} \(String(localized: "dashboard.reviewCards"))", style: .secondary, action: {})
            }
        }
    }
}
