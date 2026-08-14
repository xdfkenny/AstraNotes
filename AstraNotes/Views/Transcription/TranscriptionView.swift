// TranscriptionView.swift — AstraNotes
// Transcription UI with Soft Cryo dashboard-style design.
// Features: real-time transcription display, hexagon progress indicator,
// speaker segmentation badges, editable text, and pill-button export options.

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Transcription View

struct TranscriptionView: View {

    // MARK: - Environment

    @Environment(\.themeManager) private var tm
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var whisperService = WhisperService()
    @State private var editableText: String = ""
    @State private var selectedRecording: RecordingSession?
    @State private var selectedLanguage: String? = nil
    @State private var isTranscribing: Bool = false
    @State private var transcriptionResult: TranscriptionResult?
    @State private var showExportOptions: Bool = false
    @State private var showLanguagePicker: Bool = false
    @State private var isEditing: Bool = false
    @State private var searchText: String = ""
    @State private var copiedToClipboard: Bool = false

    // MARK: - Queries

    @Query private var recordings: [RecordingSession]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                statusSection

                if let result = transcriptionResult {
                    transcriptionContentSection(result: result)
                    exportSection
                } else {
                    recordingSelectorSection
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CryoColors.background(tm))
        .task {
            // Pre-check if model is already downloaded.
            if whisperService.isModelDownloaded {
                // Model files exist; initialize in background.
                Task {
                    await whisperService.initializeModel()
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("📝")
                    .font(.system(size: 24))
                Text(String(localized: "transcription.title"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(CryoColors.foreground(tm))
            }

            Text(String(localized: "transcription.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(CryoColors.foregroundMuted(tm))
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        CryoCard(manager: tm, style: .standard) {
            HStack(spacing: 16) {
                // Hexagon status indicator
                HexagonBadge(size: 40, manager: tm) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(CryoColors.foreground(tm))

                    Text(statusSubtitle)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                }

                Spacer()

                // Progress indicator for active operations
                statusProgressView
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private var statusProgressView: some View {
        switch whisperService.state {
        case .downloadingModel(let progress):
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(localized: "transcription.downloading"))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.6))

                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 140)
                    .tint(CryoColors.accent(tm))

                Text(String(format: "%.0f%%", progress * 100))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(CryoColors.accent(tm))
            }

        case .transcribing(let progress):
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(localized: "transcription.transcribing"))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.6))

                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 140)
                    .tint(CryoColors.accent(tm))

                Text(String(format: "%.0f%%", progress * 100))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(CryoColors.accent(tm))
            }

        case .failed(let error):
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(localized: "transcription.error"))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.red.opacity(0.8))
                Text(error)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.5))
                    .frame(width: 140, alignment: .trailing)
                    .lineLimit(2)
            }

        default:
            // Idle or completed — show a ready indicator.
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(CryoColors.accent(tm))
                        .frame(width: 6, height: 6)
                    Text(String(localized: "transcription.ready"))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CryoColors.accent(tm))
                }
            }
        }
    }

    // MARK: - Status Computed Properties

    private var statusIcon: String {
        switch whisperService.state {
        case .idle:                   return "mic"
        case .downloadingModel:      return "arrow.down.circle"
        case .transcribing:          return "waveform"
        case .completed:             return "checkmark.circle"
        case .failed:                 return "exclamationmark.triangle"
        }
    }

    private var statusTitle: String {
        switch whisperService.state {
        case .idle:                   return String(localized: "transcription.whisperEngine")
        case .downloadingModel:      return String(localized: "transcription.downloadingModel")
        case .transcribing:          return String(localized: "transcription.transcribingAudio")
        case .completed:             return String(localized: "transcription.complete")
        case .failed:                 return String(localized: "transcription.failed")
        }
    }

    private var statusSubtitle: String {
        switch whisperService.state {
        case .idle:
            return whisperService.isReady
                ? String(localized: "transcription.modelReady")
                : String(localized: "transcription.modelNotDownloaded")
        case .downloadingModel(let progress):
            return String(format: "Downloading large-v3-turbo %.0f%%", progress * 100)
        case .transcribing(let progress):
            return String(format: "Processing audio %.0f%%", progress * 100)
        case .completed:
            let count = transcriptionResult?.segments.count ?? 0
            return String(localized: "transcription.segmentsTranscribed \(count)")
        case .failed(let error):
            return error
        }
    }

    // MARK: - Recording Selector

    private var recordingSelectorSection: some View {
        CryoCard(manager: tm, style: .standard) {
            VStack(spacing: 16) {
                HStack {
                    Text(String(localized: "transcription.selectRecording"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(CryoColors.accentDark(tm))
                        .tracking(0.08)
                    Spacer()
                }

                if recordings.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "waveform.badge.mic")
                            .font(.system(size: 32))
                            .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.3))
                        Text(String(localized: "transcription.noRecordings"))
                            .font(.system(size: 14))
                            .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.5))
                        Text(String(localized: "transcription.noRecordingsHint"))
                            .font(.system(size: 12))
                            .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.4))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(recordings) { recording in
                                recordingRow(recording)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
            }
            .padding(20)
        }
    }

    private func recordingRow(_ recording: RecordingSession) -> some View {
        Button {
            selectedRecording = recording
            startTranscription(for: recording)
        } label: {
            HStack(spacing: 12) {
                // Hexagon icon
                HexagonBadge(size: 32, manager: tm) {
                    Image(systemName: "waveform")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(recording.audioFileURL)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(CryoColors.foreground(tm))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    HStack(spacing: 8) {
                        Text(formatDuration(recording.duration))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.6))

                        if !recording.subject.isEmpty && recording.subject != "No Subject" {
                            Text(recording.subject)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(CryoColors.accent(tm).opacity(0.7))
                        }
                    }
                }

                Spacer()

                if selectedRecording?.id == recording.id && isTranscribing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.7)
                        .tint(CryoColors.accent(tm))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.3))
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedRecording?.id == recording.id ? CryoColors.accentGlow(tm) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedRecording?.id == recording.id ? CryoColors.accent(tm).opacity(0.3) : CryoColors.border(tm).opacity(0.5),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isTranscribing)
    }

    // MARK: - Transcription Content Section

    private func transcriptionContentSection(result: TranscriptionResult) -> some View {
        VStack(spacing: 16) {
            // Statistics row
            statisticsRow(result: result)

            // Transcription text area
            CryoCard(manager: tm, style: .standard) {
                VStack(spacing: 12) {
                    // Header with edit/copy actions
                    HStack {
                        Text(String(localized: "transcription.transcription"))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(CryoColors.accentDark(tm))
                            .tracking(0.08)

                        Spacer()

                        // Language badge
                        if let lang = result.language, lang != "auto" {
                            languageBadge(lang)
                        }

                        // Copy button
                        Button {
                            copyToClipboard(text: editableText)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(copiedToClipboard ? String(localized: "transcription.copied") : String(localized: "common.copy"))
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(CryoColors.accentDark(tm))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(CryoColors.frost(tm))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(CryoColors.border(tm), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        // Edit/Save toggle
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isEditing.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isEditing ? "checkmark.circle" : "pencil")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(isEditing ? String(localized: "transcription.done") : String(localized: "transcription.edit"))
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(CryoColors.accentDark(tm))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(CryoColors.frost(tm))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(CryoColors.border(tm), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Segmented transcription display
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(result.segments.enumerated()), id: \.offset) { index, segment in
                                segmentView(segment: segment, index: index)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(CryoColors.backgroundWarm(tm))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(CryoColors.border(tm), lineWidth: 1)
                        )
                    }
                    .frame(maxHeight: 400)
                }
                .padding(20)
            }
        }
    }

    private func statisticsRow(result: TranscriptionResult) -> some View {
        HStack(spacing: 12) {
            statBadge(
                icon: "text.alignleft",
                value: "\(result.wordCount)",
                label: String(localized: "transcription.words")
            )
            statBadge(
                icon: "clock",
                value: result.segments.first.map { formatTime($0.startTime) } ?? "--:--",
                label: String(localized: "transcription.start")
            )
            statBadge(
                icon: "clock.arrow.2.circlepath",
                value: result.segments.last.map { formatTime($0.endTime) } ?? "--:--",
                label: String(localized: "transcription.end")
            )
            statBadge(
                icon: "chart.bar",
                value: String(format: "%.1f%%", result.confidence * 100),
                label: String(localized: "transcription.confidence")
            )

            Spacer()

            // Language badge
            if let lang = result.language {
                languageBadge(lang)
            }
        }
    }

    private func statBadge(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(CryoColors.accent(tm))

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(CryoColors.foreground(tm))

                Text(label)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(0.06)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [CryoColors.backgroundWarm(tm), CryoColors.frost(tm)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CryoColors.border(tm), lineWidth: 1)
        )
    }

    private func segmentView(segment: TranscriptionSegment, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                // Segment index badge
                Text(String(format: "%02d", index + 1))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CryoColors.accent(tm))
                    .frame(width: 28, height: 20)
                    .background(CryoColors.frost(tm))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                // Timestamp
                Text("\(formatTime(segment.startTime)) — \(formatTime(segment.endTime))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.5))

                // Confidence
                Text(String(format: "%.0f%%", segment.confidence * 100))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(
                        segment.confidence > 0.8 ? CryoColors.accent(tm).opacity(0.6) : Color.orange.opacity(0.6)
                    )

                // Speaker badge (if available)
                if let speakerID = segment.speakerID {
                    Text(String(localized: "transcription.speaker \(speakerID)"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(speakerColor(for: speakerID))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(speakerColor(for: speakerID).opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            // Segment text
            Text(segment.text)
                .font(.system(size: 14))
                .foregroundColor(CryoColors.foreground(tm))
                .lineSpacing(4)
        }
    }

    private func languageBadge(_ code: String) -> some View {
        let name = WhisperService.supportedLanguages.first(where: { $0.code == code })?.name ?? code.uppercased()
        return Text(name)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundColor(CryoColors.accentDark(tm))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(CryoColors.frost(tm))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(CryoColors.border(tm), lineWidth: 1)
            )
    }

    // MARK: - Export Section

    private var exportSection: some View {
        CryoCard(manager: tm, style: .standard) {
            VStack(spacing: 16) {
                HStack {
                    Text(String(localized: "transcription.exportOptions"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(CryoColors.accentDark(tm))
                        .tracking(0.08)
                    Spacer()
                }

                HStack(spacing: 12) {
                    // Primary: Generate Note
                    exportPillButton(
                        title: String(localized: "transcription.generateNote"),
                        icon: "sparkles",
                        isPrimary: true
                    ) {
                        // TODO: Navigate to note generation with transcription result.
                    }

                    // Copy Plain Text
                    exportPillButton(
                        title: String(localized: "transcription.copyText"),
                        icon: "doc.on.doc",
                        isPrimary: false
                    ) {
                        if let result = transcriptionResult {
                            copyToClipboard(text: result.fullText)
                        }
                    }

                    // Export as Markdown
                    exportPillButton(
                        title: String(localized: "transcription.markdown"),
                        icon: "doc.richtext",
                        isPrimary: false
                    ) {
                        exportAsMarkdown()
                    }

                    // Export SRT
                    exportPillButton(
                        title: String(localized: "transcription.srt"),
                        icon: "captions.bubble",
                        isPrimary: false
                    ) {
                        exportAsSRT()
                    }
                }
            }
            .padding(20)
        }
    }

    private func exportPillButton(
        title: String,
        icon: String,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isPrimary ? .white : CryoColors.accentDark(tm))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                isPrimary
                    ? LinearGradient(
                        colors: [CryoColors.accent(tm), CryoColors.accentDark(tm)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : CryoColors.backgroundWarm(tm)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    isPrimary ? Color.clear : CryoColors.border(tm),
                    lineWidth: 1
                )
            )
            .shadow(
                color: isPrimary ? CryoColors.shadowGlow(tm) : Color.clear,
                radius: isPrimary ? 8 : 0,
                x: 0,
                y: isPrimary ? 2 : 0
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func startTranscription(for recording: RecordingSession) {
        guard !isTranscribing else { return }
        isTranscribing = true

        let audioURL = URL(fileURLWithPath: recording.audioFileURL)

        Task {
            do {
                let result = try await whisperService.transcribe(audioURL: audioURL)
                await MainActor.run {
                    editableText = result.fullText
                    transcriptionResult = result
                    isTranscribing = false
                }
            } catch {
                await MainActor.run {
                    isTranscribing = false
                }
            }
        }
    }

    private func copyToClipboard(text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
        copiedToClipboard = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedToClipboard = false
        }
    }

    private func exportAsMarkdown() {
        guard let result = transcriptionResult else { return }

        let markdown = buildMarkdown(from: result)

        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "md")!]
        savePanel.nameFieldStringValue = "Transcription.md"

        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? markdown.write(to: url, atomically: true, encoding: .utf8)
        }
        #else
        shareText(markdown, fileName: "Transcription.md")
        #endif
    }

    private func exportAsSRT() {
        guard let result = transcriptionResult else { return }

        let srt = buildSRT(from: result)

        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "srt")!]
        savePanel.nameFieldStringValue = "Transcription.srt"

        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? srt.write(to: url, atomically: true, encoding: .utf8)
        }
        #else
        shareText(srt, fileName: "Transcription.srt")
        #endif
    }

    #if os(iOS)
    /// Shares text content via the iOS share sheet (UIActivityViewController).
    private func shareText(_ text: String, fileName: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? text.write(to: tempURL, atomically: true, encoding: .utf8)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else { return }

            let activityVC = UIActivityViewController(
                activityItems: [tempURL, text],
                applicationActivities: nil
            )
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(
                    x: rootVC.view.bounds.midX,
                    y: rootVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
            }
            rootVC.present(activityVC, animated: true)
        }
    }
    #endif

    // MARK: - Format Builders

    private func buildMarkdown(from result: TranscriptionResult) -> String {
        var md = "# Transcription\n\n"

        if let lang = result.language, lang != "auto" {
            md += "**Language:** \(lang)\n"
        }
        md += "**Word Count:** \(result.wordCount)\n"
        md += "**Confidence:** \(String(format: "%.1f%%", result.confidence * 100))\n\n---\n\n"

        for (index, segment) in result.segments.enumerated() {
            let startTime = formatTimeSRT(segment.startTime)
            let endTime = formatTimeSRT(segment.endTime)
            md += "**[\(startTime) → \(endTime)]** \(segment.text)\n\n"
        }

        md += "\n---\n*Generated by AstraNotes · \(formattedDateNow)*\n"
        return md
    }

    private func buildSRT(from result: TranscriptionResult) -> String {
        var srt = ""
        for (index, segment) in result.segments.enumerated() {
            let start = formatTimeSRT(segment.startTime)
            let end = formatTimeSRT(segment.endTime)
            srt += "\(index + 1)\n\(start) --> \(end)\n\(segment.text)\n\n"
        }
        return srt
    }

    // MARK: - Color Helpers

    /// Deterministic color for a speaker ID, drawn from a Cryo-compatible palette.
    private func speakerColor(for speakerID: Int) -> Color {
        let palette: [Color] = [
            CryoColors.accent(tm),
            Color(red: 0.65, green: 0.55, blue: 0.85), // lavender
            Color(red: 0.55, green: 0.80, blue: 0.70), // mint
            Color(red: 0.85, green: 0.65, blue: 0.55), // rose
            Color(red: 0.70, green: 0.78, blue: 0.55), // sage
        ]
        return palette[speakerID % palette.count]
    }

    // MARK: - Formatting Utilities

    private func formatDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours   = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let total = Int(time)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formatTimeSRT(_ time: TimeInterval) -> String {
        let total = Int(time)
        let hours   = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        let millis  = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, millis)
    }

    private var formattedDateNow: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Preview

#Preview {
    TranscriptionView()
        .environment(ThemeManager())
}
