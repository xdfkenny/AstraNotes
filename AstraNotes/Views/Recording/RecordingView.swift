// RecordingView.swift — AstraNotes
// Recording UI with the Astra design system.
// Features: large double-bezel record button, live waveform, mono timer,
// subject selector, file import with drag-and-drop, right-side inspector.

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Recording View

struct RecordingView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var audioService = AudioService()
    @State private var selectedSubject: String = String(localized: "recording.noSubject")
    @State private var isImporting: Bool = false
    @State private var isDragOver: Bool = false
    @State private var showSaveConfirmation: Bool = false
    @State private var savedRecordingURL: URL?
    @State private var selectedLanguage: TranscriptionLanguage = .autoDetect

    // MARK: - Queries

    @Query private var subjects: [Subject]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                headerSection

                // Asymmetric split: main recording surface + inspector
                HStack(alignment: .top, spacing: Spacing.xl) {
                    mainColumn
                        .frame(maxWidth: .infinity)
                    inspectorColumn
                        .frame(width: 260)
                }
            }
            .padding(Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceBackground)
#if os(macOS)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDroppedFiles(providers: providers)
        }
#endif
        .alert(String(localized: "recording.saved"), isPresented: $showSaveConfirmation) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            Text(String(format: String(localized: "recording.savedMessage"), savedRecordingURL?.lastPathComponent ?? "unknown"))
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "recording.title"))
                .font(TypeScale.title)
                .foregroundStyle(.textPrimary)
            Text(String(localized: "recording.subtitle"))
                .font(TypeScale.body)
                .foregroundStyle(.textSecondary)
        }
    }

    // MARK: - Main Column (waveform + controls)

    private var mainColumn: some View {
        VStack(spacing: Spacing.xl) {
            // Waveform panel
            AstraCard(tint: audioService.state == .recording ? Color.semanticDanger.opacity(0.04) : .clear) {
                VStack(spacing: Spacing.lg) {
                    HStack(spacing: Spacing.sm) {
                        StatusDot(
                            kind: audioService.state == .recording ? .recording : .idle,
                            label: stateLabel
                        )
                        Spacer()
                        Text(String(format: "%.0f dB", audioService.averagePower))
                            .font(.astraMono(11))
                            .foregroundStyle(.textTertiary)
                    }

                    // Waveform canvas
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.card)
                            .fill(Color.hairline.opacity(0.35))
                            .frame(height: 120)

                        if audioService.state == .idle {
                            VStack(spacing: Spacing.sm) {
                                AstraIconView(.graphicEq, size: 26)
                                    .foregroundStyle(.textTertiary.opacity(0.5))
                                Text(String(localized: "recording.ready"))
                                    .font(TypeScale.caption)
                                    .foregroundStyle(.textTertiary)
                            }
                        } else if audioService.state == .paused {
                            VStack(spacing: Spacing.sm) {
                                AstraIconView(.pauseCircle, size: 26)
                                    .foregroundStyle(Color.accent.opacity(0.6))
                                Text(String(localized: "recording.paused"))
                                    .font(TypeScale.caption)
                                    .foregroundStyle(Color.accent.opacity(0.7))
                            }
                        } else if !audioService.waveformData.isEmpty {
                            WaveformView(
                                levels: audioService.waveformData.map(Double.init),
                                isActive: audioService.state == .recording
                            )
                            .frame(height: 120)
                        } else {
                            ProgressView()
                                .controlSize(.small)
                                .tint(Color.accent)
                        }
                    }
                }
                .padding(LayoutTokens.cardPadding)
            }

            // Timer + state
            VStack(spacing: Spacing.xs) {
                Text(audioService.formattedTime)
                    .font(.astraMono(28, .light))
                    .monospacedDigit()
                    .foregroundStyle(.textPrimary)
                    .frame(height: 34)

                MicroLabel(text: stateLabel)
            }

            // Controls
            HStack(spacing: Spacing.xl) {
                // Pause / Resume
                AstraIconButton(
                    icon: audioService.state == .paused ? .playArrow : .pause,
                    help: String(localized: "recording.pauseResume")
                ) {
                    withAnimation(Motion.stateChange) {
                        if audioService.state == .recording {
                            audioService.pauseRecording()
                        } else if audioService.state == .paused {
                            try? audioService.resumeRecording()
                        }
                    }
                }
                .disabled(audioService.state == .idle)
                .opacity(audioService.state == .idle ? 0.4 : 1)

                // Record / Stop (double-bezel)
                recordButton

                // Import
                AstraIconButton(
                    icon: .folder,
                    help: String(localized: "recording.importAudioFile")
                ) {
                    isImporting = true
                }
                .fileImporter(
                    isPresented: $isImporting,
                    allowedContentTypes: [.audio],
                    allowsMultipleSelection: false
                ) { result in
                    handleImportedFile(result: result)
                }
            }
            .padding(.top, Spacing.xs)
        }
    }

    /// Double-bezel record button: outer material ring, inner danger circle.
    private var recordButton: some View {
        Button {
            withAnimation(Motion.entrance) {
                handleRecordButtonTap()
            }
        } label: {
            ZStack {
                // Outer ring (material shell)
                Circle()
                    .fill(Color.surface.opacity(0.6))
                    .frame(width: 64, height: 64)
                    .overlay(Circle().stroke(Color.hairline, lineWidth: 1))

                // Inner core
                Circle()
                    .fill(audioService.state == .recording ? Color.semanticDanger : Color.accent)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))

                AstraIconView(buttonIcon, size: 18)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        #if os(macOS)
        .help(String(localized: "recording.startStop"))
        #endif
        .accessibilityLabel(String(localized: "recording.startStop"))
    }

    private var buttonIcon: AstraIcon {
        audioService.state == .recording ? .stop : .mic
    }

    private var stateLabel: String {
        switch audioService.state {
        case .idle:     return String(localized: "recording.idle")
        case .recording: return audioService.isSilent ? String(localized: "recording.silentAutoPause") : String(localized: "recording.recording")
        case .paused:   return String(localized: "recording.paused")
        case .stopped:  return String(localized: "recording.stopped")
        case .error:    return String(localized: "recording.error")
        }
    }

    // MARK: - Inspector Column

    private var inspectorColumn: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionHeader(title: String(localized: "recording.lecture"), icon: .info)

            // Subject picker
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(String(localized: "recording.subject"))
                    .font(TypeScale.caption)
                    .foregroundStyle(.textSecondary)

                Menu {
                    Button(String(localized: "recording.noSubject")) {
                        selectedSubject = String(localized: "recording.noSubject")
                    }
                    Divider()
                    ForEach(subjects) { subject in
                        Button {
                            selectedSubject = subject.name
                        } label: {
                            HStack {
                                Text(subject.name)
                                Text("(\(subject.level.displayName))")
                                    .foregroundStyle(.textTertiary)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Text(selectedSubject)
                            .font(TypeScale.body)
                            .foregroundStyle(.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        AstraIconView(.expandMore, size: 10)
                            .foregroundStyle(.textTertiary)
                    }
                    .padding(.horizontal, Spacing.md)
                    .frame(height: 32)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.control))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.control)
                            .stroke(Color.hairline, lineWidth: 1)
                    )
                }
                #if os(macOS)
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                #endif
            }

            // Language
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(String(localized: "settings.whisperLanguage"))
                    .font(TypeScale.caption)
                    .foregroundStyle(.textSecondary)

                Picker("", selection: $selectedLanguage) {
                    ForEach(TranscriptionLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
                .overlay(Color.hairline)

            // Transcription options
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(String(localized: "transcription.title"))
                    .font(TypeScale.subheading)
                    .foregroundStyle(.textPrimary)

                HStack(spacing: Spacing.xs) {
                    AstraIconView(.checkCircle, size: 12)
                        .foregroundStyle(Color.accent)
                    Text(String(localized: "recording.transcribeAfterStop"))
                        .font(TypeScale.caption)
                        .foregroundStyle(.textSecondary)
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.panel))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.panel)
                .stroke(Color.hairline, lineWidth: 1)
        )
    }

    // MARK: - Import (Drag & Drop) Section

    private var importSection: some View {
        VStack(spacing: Spacing.md) {
            Text(String(localized: "recording.dragDrop"))
                .font(TypeScale.body)
                .foregroundStyle(.textSecondary)

            RoundedRectangle(cornerRadius: Radius.panel)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                )
                .foregroundStyle(isDragOver ? Color.accent : Color.hairline)
                .frame(height: 90)
                .background(
                    RoundedRectangle(cornerRadius: Radius.panel)
                        .fill(isDragOver ? Color.accentContainer : Color.clear)
                )
                .overlay(
                    VStack(spacing: Spacing.sm) {
                        AstraIconView(.download, size: 22)
                            .foregroundStyle(isDragOver ? Color.accent : Color.textTertiary)

                        HStack(spacing: Spacing.sm) {
                            ForEach([".m4a", ".mp3", ".wav", ".aac"], id: \.self) { ext in
                                Text(ext)
                                    .font(.astraMono(11))
                                    .foregroundStyle(.textTertiary.opacity(0.7))
                            }
                        }
                    }
                )
                .scaleEffect(isDragOver ? 1.01 : 1.0)
                .animation(.easeOut(duration: 0.2), value: isDragOver)
        }
    }

    // MARK: - Actions

    private func handleRecordButtonTap() {
        switch audioService.state {
        case .idle, .stopped:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HHmmss"
            let fileName = "Recording_\(formatter.string(from: Date()))"
            Task {
                do {
                    try await audioService.startRecording(fileName: fileName)
                } catch {
                    audioService.errorMessage = error.localizedDescription
                }
            }

        case .recording, .paused:
            if let url = audioService.stopRecording() {
                savedRecordingURL = url
                saveRecordingSession(url: url)
                showSaveConfirmation = true
            }

        case .error:
            // Transient error state (e.g. mic permission denied); nothing to stop.
            break
        }
    }

    private func saveRecordingSession(url: URL) {
        let subjectName = selectedSubject == String(localized: "recording.noSubject") ? nil : selectedSubject
        let session = RecordingSession(
            title: url.deletingPathExtension().lastPathComponent,
            subjectName: subjectName,
            date: Date(),
            duration: audioService.currentTime,
            fileName: url.lastPathComponent,
            filePath: url
        )
        modelContext.insert(session)
    }

    private func handleImportedFile(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            // Access the security-scoped resource for file importer results.
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            saveRecordingSession(url: url)
            // TODO: Present transcription option after import.

        case .failure(let error):
            audioService.errorMessage = error.localizedDescription
        }
    }

    #if os(macOS)
    private func handleDroppedFiles(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
            guard let data = data as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

            Task { @MainActor in
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }

                saveRecordingSession(url: url)
                savedRecordingURL = url
                showSaveConfirmation = true
            }
        }

        return true
    }
    #endif
}

// MARK: - URL Extension (file size)

extension URL {
    /// File size in bytes, or 0 if unavailable.
    var fileSize: Int64 {
        (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int64) ?? 0
    }
}

// MARK: - Preview

#Preview {
    RecordingView()
}
