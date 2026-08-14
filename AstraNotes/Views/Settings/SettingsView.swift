import SwiftUI
import SwiftData

// MARK: - SettingsView
// The application settings screen organized into card groups:
// Appearance (theme picker), AI & Services (API key, vault path),
// Transcription (language, auto-transcribe), Note Generation (style,
// quiz difficulty), and an About section. All inputs and toggles use
// the Soft Cryo styling through CryoCard, CryoButton, and CryoInput.

struct SettingsView: View {
    @Environment(\.themeManager) private var tm
    @Query private var settings: [AppSettings]
    @State private var deepSeekKey: String = ""
    @State private var obsidianPath: String = ""
    @State private var whisperLanguage: String = "auto"
    @State private var autoTranscribe: Bool = true
    @State private var noteStyle: String = "detailed"
    @State private var quizDifficulty: String = "mixed"
    @State private var selectedTheme: ThemeMode = .system

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                settingsHeader

                // Appearance
                settingsCard(String(localized: "settings.appearance")) {
                    VStack(spacing: 16) {
                        themePicker

                        // Theme preview chips
                        HStack(spacing: 12) {
                            themePreviewChip(String(localized: "settings.light"), mode: .light)
                            themePreviewChip(String(localized: "settings.dark"), mode: .dark)
                            themePreviewChip(String(localized: "settings.system"), mode: .system)
                        }
                    }
                }

                // API Keys & Services
                settingsCard(String(localized: "settings.aiServices")) {
                    VStack(spacing: 16) {
                        settingsRow(String(localized: "settings.deepSeekKey")) {
                            SecureField("sk-...", text: $deepSeekKey)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(CryoColors.foreground(tm))
                        }

                        settingsRow(String(localized: "settings.obsidianVault")) {
                            HStack {
                                Text(obsidianPath.isEmpty ? String(localized: "settings.notSelected") : obsidianPath)
                                    .font(.system(size: 14))
                                    .foregroundColor(CryoColors.foreground(tm))
                                    .lineLimit(1)
                                Spacer()
                                CryoButton(String(localized: "settings.chooseVault"), style: .secondary, action: {})
                            }
                        }
                    }
                }

                // Transcription
                settingsCard(String(localized: "settings.transcription")) {
                    VStack(spacing: 16) {
                        settingsRow(String(localized: "settings.whisperLanguage")) {
                            Picker("", selection: $whisperLanguage) {
                                Text(String(localized: "settings.autoDetect")).tag("auto")
                                Text(String(localized: "settings.english")).tag("en")
                                Text(String(localized: "settings.spanish")).tag("es")
                                Text(String(localized: "settings.chinese")).tag("zh")
                            }
                            .labelsHidden()
                            .tint(CryoColors.accent(tm))
                        }

                        settingsToggle(String(localized: "settings.autoTranscribe"), isOn: $autoTranscribe)
                    }
                }

                // Note Generation
                settingsCard(String(localized: "settings.noteGeneration")) {
                    VStack(spacing: 16) {
                        settingsRow(String(localized: "settings.style")) {
                            Picker("", selection: $noteStyle) {
                                Text(String(localized: "settings.detailed")).tag("detailed")
                                Text(String(localized: "settings.concise")).tag("concise")
                                Text(String(localized: "settings.examFocused")).tag("exam-focused")
                            }
                            .labelsHidden()
                            .tint(CryoColors.accent(tm))
                        }

                        settingsRow(String(localized: "settings.quizDifficulty")) {
                            Picker("", selection: $quizDifficulty) {
                                Text(String(localized: "settings.sl")).tag("sl")
                                Text(String(localized: "settings.hl")).tag("hl")
                                Text(String(localized: "settings.mixed")).tag("mixed")
                            }
                            .labelsHidden()
                            .tint(CryoColors.accent(tm))
                        }
                    }
                }

                // MARK: - App Language
                settingsCard(String(localized: "settings.language")) {
                    HStack {
                        Text(String(localized: "settings.language"))
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        Picker("", selection: Binding(
                            get: { settings.first?.appLanguage ?? "en" },
                            set: { settings.first?.appLanguage = $0 }
                        )) {
                            ForEach(LocalizationManager.shared.supportedAppLanguages, id: \.code) { lang in
                                Text(String(localized: "lang.\(lang.code)")).tag(lang.code)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 140)
                    }
                    Text(String(localized: "settings.languageHint"))
                        .font(.system(size: 11))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                }

                // MARK: - Note Output Language
                settingsCard(String(localized: "settings.outputLanguage")) {
                    HStack {
                        Text(String(localized: "settings.outputLanguage"))
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        Picker("", selection: Binding(
                            get: { settings.first?.noteOutputLanguage ?? "auto" },
                            set: { settings.first?.noteOutputLanguage = $0 }
                        )) {
                            Text(String(localized: "settings.outputLanguageAuto")).tag("auto")
                            ForEach(LocalizationManager.shared.supportedAppLanguages, id: \.code) { lang in
                                Text(String(localized: "lang.\(lang.code)")).tag(lang.code)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 140)
                    }
                }

                // About
                settingsCard(String(localized: "settings.about")) {
                    VStack(spacing: 8) {
                        HStack {
                            Text("\u{2744}\u{FE0F} AstraNotes")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(CryoColors.foreground(tm))
                            Spacer()
                            Text(String(localized: "settings.version"))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(CryoColors.foregroundMuted(tm))
                        }
                        Text(String(localized: "settings.aboutDescription"))
                            .font(.system(size: 13))
                            .foregroundColor(CryoColors.foregroundMuted(tm))
                    }
                }
            }
            .padding(32)
        }
        .background(CryoColors.background(tm))
    }

    // MARK: - Settings Header

    private var settingsHeader: some View {
        Text(String(localized: "settings.title"))
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(CryoColors.foreground(tm))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Reusable Card Container

    private func settingsCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        CryoCard(manager: tm, style: .standard) {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
                    .textCase(.uppercase)
                    .tracking(0.05)

                content()
            }
            .padding(20)
        }
    }

    // MARK: - Row Layout Helper

    private func settingsRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(CryoColors.foreground(tm))
            Spacer()
            content()
        }
    }

    // MARK: - Toggle Helper

    private func settingsToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(CryoColors.foreground(tm))
        }
        .toggleStyle(.switch)
        .tint(CryoColors.accent(tm))
    }

    // MARK: - Theme Picker

    private var themePicker: some View {
        HStack(spacing: 8) {
            ForEach(ThemeMode.allCases, id: \.self) { mode in
                let isSelected = selectedTheme == mode

                Button {
                    selectedTheme = mode
                    tm.mode = mode
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12))
                        Text(mode.displayName)
                            .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        isSelected
                            ? CryoColors.primaryGradient(tm)
                            : CryoColors.frost(tm)
                    )
                    .foregroundColor(isSelected ? .white : CryoColors.foreground(tm))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? .clear : CryoColors.border(tm),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Theme Preview Chip

    private func themePreviewChip(_ name: String, mode: ThemeMode) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(mode == .dark ? Color(hex: "#0F1729") : Color(hex: "#F0F7FF"))
                .frame(width: 60, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(CryoColors.border(tm), lineWidth: 1)
                )

            Text(name)
                .font(.system(size: 11))
                .foregroundColor(CryoColors.foregroundMuted(tm))
        }
    }
}
