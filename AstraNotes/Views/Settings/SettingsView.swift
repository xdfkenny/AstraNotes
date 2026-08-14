import SwiftUI
import SwiftData

// MARK: - SettingsView
// Settings organized into grouped cards: Appearance (theme), AI & Services
// (DeepSeek key, Obsidian vault), Transcription, Note Generation,
// App Language, Note Output Language, and About. Values persist to the
// AppSettings model; the theme picker drives ThemeManager.

struct SettingsView: View {
    @Environment(\.themeManager) private var tm
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]

    @State private var obsidianService = ObsidianService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                settingsHeader

                settingsCard(String(localized: "settings.appearance")) {
                    themePicker
                }

                settingsCard(String(localized: "settings.aiServices")) {
                    VStack(spacing: Spacing.lg) {
                        // DeepSeek API key
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(String(localized: "settings.deepSeekKey"))
                                .font(TypeScale.caption)
                                .foregroundStyle(.textSecondary)
                            SecureField("sk-...", text: apiKeyBinding)
                                .textFieldStyle(.plain)
                                .font(.astraMono(13))
                                .foregroundStyle(.textPrimary)
                                .padding(.horizontal, Spacing.md)
                                .frame(height: 32)
                                .background(Color.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.control))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.control)
                                        .stroke(Color.hairline, lineWidth: 1)
                                )
                        }

                        // Obsidian vault
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(String(localized: "settings.obsidianVault"))
                                .font(TypeScale.caption)
                                .foregroundStyle(.textSecondary)
                            HStack(spacing: Spacing.md) {
                                Text(obsidianService.vaultPath.isEmpty
                                     ? String(localized: "settings.notSelected")
                                     : obsidianService.vaultPath)
                                    .font(.astraMono(12))
                                    .foregroundStyle(obsidianService.vaultPath.isEmpty ? .textTertiary : .textPrimary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                AstraButton(
                                    title: String(localized: "settings.chooseVault"),
                                    style: .secondary
                                ) {
                                    obsidianService.selectVault()
                                }
                            }
                            .padding(Spacing.sm)
                            .background(Color.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.control))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.control)
                                    .stroke(Color.hairline, lineWidth: 1)
                            )

                            if obsidianService.isVaultValid {
                                HStack(spacing: Spacing.xs) {
                                    StatusDot(kind: .ready)
                                    Text("\(obsidianService.vaultStructure.count) \(String(localized: "sidebar.subjects"))")
                                        .font(TypeScale.caption)
                                        .foregroundStyle(.textSecondary)
                                }
                            } else if !obsidianService.vaultPath.isEmpty {
                                HStack(spacing: Spacing.xs) {
                                    StatusDot(kind: .processing)
                                    Text(String(localized: "settings.vaultInvalid"))
                                        .font(TypeScale.caption)
                                        .foregroundStyle(.textSecondary)
                                }
                            }
                        }
                    }
                }

                settingsCard(String(localized: "settings.transcription")) {
                    VStack(spacing: Spacing.lg) {
                        settingsRow(String(localized: "settings.whisperLanguage")) {
                            Picker("", selection: whisperLanguageBinding) {
                                Text(String(localized: "settings.autoDetect")).tag("auto")
                                Text(String(localized: "settings.english")).tag("en")
                                Text(String(localized: "settings.spanish")).tag("es")
                                Text(String(localized: "settings.chinese")).tag("zh")
                            }
                            .labelsHidden()
                            .tint(Color.accent)
                        }

                        settingsToggle(String(localized: "settings.autoTranscribe"), isOn: autoTranscribeBinding)
                    }
                }

                settingsCard(String(localized: "settings.noteGeneration")) {
                    VStack(spacing: Spacing.lg) {
                        settingsRow(String(localized: "settings.style")) {
                            Picker("", selection: noteStyleBinding) {
                                Text(String(localized: "settings.detailed")).tag("detailed")
                                Text(String(localized: "settings.concise")).tag("concise")
                                Text(String(localized: "settings.examFocused")).tag("exam-focused")
                            }
                            .labelsHidden()
                            .tint(Color.accent)
                        }

                        settingsRow(String(localized: "settings.quizDifficulty")) {
                            Picker("", selection: quizDifficultyBinding) {
                                Text(String(localized: "settings.sl")).tag("sl")
                                Text(String(localized: "settings.hl")).tag("hl")
                                Text(String(localized: "settings.mixed")).tag("mixed")
                            }
                            .labelsHidden()
                            .tint(Color.accent)
                        }
                    }
                }

                settingsCard(String(localized: "settings.language")) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        settingsRow(String(localized: "settings.language")) {
                            Picker("", selection: appLanguageBinding) {
                                ForEach(LocalizationManager.supportedAppLanguages, id: \.code) { lang in
                                    Text(String(localized: "lang.\(lang.code)")).tag(lang.code)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 160)
                        }
                        Text(String(localized: "settings.languageHint"))
                            .font(TypeScale.caption)
                            .foregroundStyle(.textTertiary)
                    }
                }

                settingsCard(String(localized: "settings.outputLanguage")) {
                    settingsRow(String(localized: "settings.outputLanguage")) {
                        Picker("", selection: noteOutputLanguageBinding) {
                            Text(String(localized: "settings.outputLanguageAuto")).tag("auto")
                            ForEach(LocalizationManager.supportedAppLanguages, id: \.code) { lang in
                                Text(String(localized: "lang.\(lang.code)")).tag(lang.code)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 160)
                    }
                }

                settingsCard(String(localized: "settings.about")) {
                    VStack(spacing: Spacing.sm) {
                        HStack {
                            AstraIconView(.autoAwesome, size: 14)
                                .foregroundStyle(Color.accent)
                                .frame(width: 26, height: 26)
                                .background(Color.accentContainer)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.micro))
                            Text("AstraNotes")
                                .font(TypeScale.heading)
                                .foregroundStyle(.textPrimary)
                            Spacer()
                            Text("\(Bundle.main.fullVersion)")
                                .font(.astraMono(11))
                                .foregroundStyle(.textTertiary)
                        }
                        Text(String(localized: "settings.aboutDescription"))
                            .font(TypeScale.body)
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
            .padding(Spacing.xxl)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color.surfaceBackground)
    }

    // MARK: - Settings Header

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "settings.title"))
                .font(TypeScale.title)
                .foregroundStyle(.textPrimary)
        }
    }

    // MARK: - Reusable Card Container

    private func settingsCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        AstraCard {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                SectionHeader(title: title)
                content()
            }
        }
    }

    // MARK: - Row Layout Helper

    private func settingsRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center) {
            Text(label)
                .font(TypeScale.body)
                .foregroundStyle(.textPrimary)
            Spacer()
            content()
        }
    }

    // MARK: - Toggle Helper

    private func settingsToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(TypeScale.body)
                .foregroundStyle(.textPrimary)
        }
        .toggleStyle(.switch)
        .tint(Color.accent)
    }

    // MARK: - Theme Picker

    private var themePicker: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(ThemeMode.allCases, id: \.self) { mode in
                let isSelected = tm.mode == mode

                Button {
                    withAnimation(Motion.stateChange) {
                        tm.mode = mode
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        AstraIconView(mode.astraIcon, size: 12)
                        Text(mode.displayName)
                            .font(.astraBody(12, isSelected ? .semibold : .regular))
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(isSelected ? Color.accent : Color.surface)
                    .foregroundStyle(isSelected ? Color.onAccent : Color.textPrimary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(isSelected ? Color.clear : Color.hairline, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Model Bindings
    // Lazy-create the singleton AppSettings row so settings persist.

    private var settingsModel: AppSettings {
        if let existing = settings.first {
            return existing
        }
        let row = AppSettings()
        modelContext.insert(row)
        return row
    }

    private var apiKeyBinding: Binding<String> {
        Binding(
            get: { settingsModel.deepSeekAPIKey },
            set: { settingsModel.deepSeekAPIKey = $0 }
        )
    }

    private var whisperLanguageBinding: Binding<String> {
        Binding(
            get: { settingsModel.whisperLanguage },
            set: { settingsModel.whisperLanguage = $0 }
        )
    }

    private var autoTranscribeBinding: Binding<Bool> {
        Binding(
            get: { settingsModel.autoTranscribe },
            set: { settingsModel.autoTranscribe = $0 }
        )
    }

    private var noteStyleBinding: Binding<String> {
        Binding(
            get: { settingsModel.noteGenerationStyle },
            set: { settingsModel.noteGenerationStyle = $0 }
        )
    }

    private var quizDifficultyBinding: Binding<String> {
        Binding(
            get: { settingsModel.quizDifficulty },
            set: { settingsModel.quizDifficulty = $0 }
        )
    }

    private var appLanguageBinding: Binding<String> {
        Binding(
            get: { settingsModel.appLanguage },
            set: { settingsModel.appLanguage = $0 }
        )
    }

    private var noteOutputLanguageBinding: Binding<String> {
        Binding(
            get: { settingsModel.noteOutputLanguage },
            set: { settingsModel.noteOutputLanguage = $0 }
        )
    }
}
