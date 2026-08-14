// RecordingView.swift — AstraNotes
// Recording UI with Soft Cryo ice crystal design aesthetic.
// Features: large circular record button, waveform visualization, timer,
// subject selector, file import with drag-and-drop.

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Recording View

struct RecordingView: View {

    // MARK: - Environment

    @Environment(\.themeManager) private var tm
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var audioService = AudioService()
    @State private var selectedSubject: String = String(localized: "recording.noSubject")
    @State private var isImporting: Bool = false
    @State private var isDragOver: Bool = false
    @State private var showSaveConfirmation: Bool = false
    @State private var savedRecordingURL: URL?

    // MARK: - Queries

    @Query private var subjects: [Subject]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                waveformSection
                timerSection
                controlsSection
                subjectSelectorSection
                importSection
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CryoColors.background(tm))
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
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("❄️")
                    .font(.system(size: 24))
                Text(String(localized: "recording.title"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(CryoColors.foreground(tm))
            }

            Text(String(localized: "recording.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(CryoColors.foregroundMuted(tm))
        }
    }

    // MARK: - Waveform Section

    private var waveformSection: some View {
        CryoCard(manager: tm, style: .standard) {
            VStack(spacing: 16) {
                HStack(spacing: 6) {
                    Text(String(localized: "recording.liveWaveform"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(CryoColors.accentDark(tm))
                        .tracking(0.08)
                    Spacer()

                    // Power level indicator
                    Text(String(format: "%.0f dB", audioService.averagePower))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.6))
                }

                // Waveform canvas
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(CryoColors.frost(tm))
                        .frame(height: 120)

                    if audioService.state == .idle {
                        VStack(spacing: 8) {
                            Image(systemName: "waveform")
                                .font(.system(size: 28))
                                .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.3))
                            Text(String(localized: "recording.ready"))
                                .font(.system(size: 13))
                                .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.4))
                        }
                    } else if audioService.state == .paused {
                        VStack(spacing: 8) {
                            Image(systemName: "pause.circle")
                                .font(.system(size: 28))
                                .foregroundColor(CryoColors.accent(tm).opacity(0.5))
                            Text(String(localized: "recording.paused"))
                                .font(.system(size: 13))
                                .foregroundColor(CryoColors.accent(tm).opacity(0.6))
                        }
                    } else if !audioService.waveformData.isEmpty {
                        WaveformView(data: audioService.waveformData, manager: tm)
                            .frame(height: 120)
                    } else {
                        // Recording started but no data yet (very brief moment)
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.6)
                            .tint(CryoColors.accent(tm))
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(spacing: 6) {
            Text(audioService.formattedTime)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundColor(CryoColors.foreground(tm))
                .tracking(0.05)
                .frame(height: 56)

            // Recording state label
            HStack(spacing: 6) {
                Circle()
                    .fill(stateIndicatorColor)
                    .frame(width: 8, height: 8)

                Text(stateLabel)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
                    .textCase(.uppercase)
                    .tracking(0.06)
            }
        }
    }

    private var stateIndicatorColor: Color {
        switch audioService.state {
        case .recording:
            return .red.opacity(audioService.isSilent ? 0.4 : 1.0)
        case .paused:
            return CryoColors.accent(tm).opacity(0.5)
        case .idle, .stopped:
            return CryoColors.foregroundMuted(tm).opacity(0.3)
        }
    }

    private var stateLabel: String {
        switch audioService.state {
        case .idle:     return String(localized: "recording.idle")
        case .recording: return audioService.isSilent ? String(localized: "recording.silentAutoPause") : String(localized: "recording.recording")
        case .paused:   return String(localized: "recording.paused")
        case .stopped:  return String(localized: "recording.stopped")
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: 24) {
            // Pause / Resume Button (40x40)
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if audioService.state == .recording {
                        audioService.pauseRecording()
                    } else if audioService.state == .paused {
                        try? audioService.resumeRecording()
                    }
                }
            } label: {
                Image(systemName: audioService.state == .paused ? "play.fill" : "pause.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(CryoColors.accentDark(tm))
                    .frame(width: 40, height: 40)
                    .background(CryoColors.backgroundWarm(tm))
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(CryoColors.border(tm), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(audioService.state == .idle)
            .opacity(audioService.state == .idle ? 0.4 : 1.0)
#if os(macOS)
            .help("Pause / Resume recording")
#endif

            // Record / Stop Button (80x80)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    handleRecordButtonTap()
                }
            } label: {
                ZStack {
                    // Glow ring
                    Circle()
                        .stroke(
                            CryoColors.accent(tm).opacity(audioService.state == .recording ? 0.3 : 0.15),
                            lineWidth: 2
                        )
                        .frame(width: 96, height: 96)

                    // Main button
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: buttonGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(
                            color: CryoColors.shadowGlow(tm),
                            radius: audioService.state == .recording ? 24 : 16,
                            x: 0,
                            y: 0
                        )

                    // Pulsing overlay when recording
                    if audioService.state == .recording {
                        Circle()
                            .stroke(CryoColors.accent(tm).opacity(0.4), lineWidth: 1.5)
                            .frame(width: 80, height: 80)
                            .scaleEffect(recordingPulseScale)
                            .opacity(2 - recordingPulseScale)
                    }

                    Image(systemName: buttonIcon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
#if os(macOS)
            .help("Start / Stop recording")
#endif

            // Import Button (40x40)
            Button {
                isImporting = true
            } label: {
                Image(systemName: "folder")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(CryoColors.accentDark(tm))
                    .frame(width: 40, height: 40)
                    .background(CryoColors.backgroundWarm(tm))
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(CryoColors.border(tm), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                handleImportedFile(result: result)
            }
#if os(macOS)
            .help("Import an audio file")
#endif
        }
    }

    private var buttonGradientColors: [Color] {
        if audioService.state == .recording {
            return [Color.red.opacity(0.9), Color.red.opacity(0.7)]
        }
        return [CryoColors.accent(tm), CryoColors.accentDark(tm)]
    }

    private var buttonIcon: String {
        if audioService.state == .recording {
            return "stop.fill"
        }
        return "mic.fill"
    }

    // Simple pulse animation for the record button while recording.
    private var recordingPulseScale: CGFloat {
        let phase = Date().timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.5)
        return 1.0 + 0.08 * sin(phase * .pi * 2)
    }

    // MARK: - Subject Selector Section

    private var subjectSelectorSection: some View {
        HStack(spacing: 12) {
            Text(String(localized: "recording.subject"))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(CryoColors.foregroundMuted(tm))

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
                                .foregroundColor(CryoColors.foregroundMuted(tm))
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedSubject)
                        .font(.system(size: 14))
                        .foregroundColor(CryoColors.foreground(tm))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(CryoColors.backgroundWarm(tm))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(CryoColors.border(tm), lineWidth: 1)
                )
            }
            #if os(macOS)
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            #endif
        }
    }

    // MARK: - Import (Drag & Drop) Section

    private var importSection: some View {
        VStack(spacing: 12) {
            Text(String(localized: "recording.dragDrop"))
                .font(.system(size: 13))
                .foregroundColor(CryoColors.foregroundMuted(tm))

            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .foregroundColor(isDragOver ? CryoColors.accent(tm) : CryoColors.border(tm))
                .frame(height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(isDragOver ? CryoColors.accentGlow(tm) : .clear)
                )
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 24))
                            .foregroundColor(
                                isDragOver ? CryoColors.accent(tm) : CryoColors.foregroundMuted(tm).opacity(0.4)
                            )

                        HStack(spacing: 8) {
                            ForEach([".m4a", ".mp3", ".wav", ".aac"], id: \.self) { ext in
                                Text(ext)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.4))
                            }
                        }
                    }
                )
                .scaleEffect(isDragOver ? 1.02 : 1.0)
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

        case .recording:
            if let url = audioService.stopRecording() {
                savedRecordingURL = url
                saveRecordingSession(url: url)
                showSaveConfirmation = true
            }

        case .paused:
            if let url = audioService.stopRecording() {
                savedRecordingURL = url
                saveRecordingSession(url: url)
                showSaveConfirmation = true
            }
        }
    }

    private func saveRecordingSession(url: URL) {
        let session = RecordingSession(
            audioFileURL: url.path,
            subject: selectedSubject,
            duration: audioService.currentTime,
            dateRecorded: Date(),
            fileSize: url.fileSize
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

// MARK: - Waveform View

/// Renders a real-time bar-style waveform visualization using SwiftUI Canvas.
struct WaveformView: View {
    let data: [Float]
    let manager: ThemeManager

    var body: some View {
        Canvas { context, size in
            guard !data.isEmpty else { return }

            let barWidth = size.width / CGFloat(data.count)
            let centerY = size.height / 2

            for (index, sample) in data.enumerated() {
                let normalizedHeight = CGFloat(sample) * (size.height / 2) * 0.8
                let barHeight = max(1, normalizedHeight)
                let x = CGFloat(index) * barWidth + barWidth * 0.5
                let rect = CGRect(
                    x: x - barWidth * 0.4,
                    y: centerY - barHeight,
                    width: max(1, barWidth - 1),
                    height: barHeight * 2
                )

                // Main bar
                context.fill(
                    Path(roundedRect: rect, cornerRadius: barWidth / 2),
                    with: .color(CryoColors.accent(manager).opacity(0.7))
                )

                // Subtle glow at top and bottom
                let glowRect = CGRect(
                    x: x - barWidth * 0.6,
                    y: centerY - barHeight,
                    width: max(1, barWidth + 1),
                    height: 3
                )
                context.fill(
                    Path(roundedRect: glowRect, cornerRadius: 1.5),
                    with: .color(CryoColors.accentLight(manager).opacity(0.5))
                )

                let glowBottomRect = CGRect(
                    x: x - barWidth * 0.6,
                    y: centerY + barHeight - 3,
                    width: max(1, barWidth + 1),
                    height: 3
                )
                context.fill(
                    Path(roundedRect: glowBottomRect, cornerRadius: 1.5),
                    with: .color(CryoColors.accentLight(manager).opacity(0.5))
                )
            }
        }
    }
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
        .environment(ThemeManager())
}
