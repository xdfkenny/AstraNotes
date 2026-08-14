// TranscriptionView.swift — AstraNotes
// Transcription UI with the Astra design system.
// Features: Whisper status panel, recording selector, segmented
// transcription display with speaker badges, export options.

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

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var whisperService = WhisperService()
    @State private var editableText: String = ""
    @State private var selectedRecording: RecordingSession?
    @State private var isTranscribing: Bool = false
    @State private var transcriptionResult: TranscriptionResult?
    @State private var isEditing: Bool = false
    @State private var copiedToClipboard: Bool = false

    // MARK: - Queries

    @Query private var recordings: [RecordingSession]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                headerSection
                statusSection

                if let result = transcriptionResult {
                    transcriptionContentSection(result: result)
                    exportSection
                } else {
                    recordingSelectorSection
                }
            }
            .padding(Spacing.xxl)
            .frame(maxWidth: Layout.contentMaxWidth + 240, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceBackground)
        .task {
            // Pre-check if model is already downloaded.
            if whisperService.isModelDownloaded {
                Task {
                    await whisperService.initializeModel()
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "transcription.title"))
                .font(TypeScale.title)
                .foregroundStyle(.textPrimary)
            Text(String(localized: "transcription.subtitle"))
                .font(TypeScale.body)
                .foregroundStyle(.textSecondary)
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        AstraCard {
            HStack(spacing: Spacing.lg) {
                // Status adornment
                AstraAdornment(icon: statusIcon, tint: statusColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(TypeScale.subheading)
                        .foregroundStyle(.textPrimary)
                    Text(statusSubtitle)
                        .font(.astraMono(12))
                        .foregroundStyle(.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                statusProgressView
            }
        }
    }

    @ViewBuilder
    private var statusProgressView: some View {
        switch whisperService.state {
        case .downloadingModel(let progress):
            progressBlock(
                label: String(localized: "transcription.downloading"),
                progress: progress
            )
        case .transcribing(let progress):
            progressBlock(
                label: String(localized: "transcription.transcribing"),
                progress: progress
            )

        case .failed(let error):
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(String(localized: "transcription.error"))
                    .font(.astraMono(11, .semibold))
                    .foregroundStyle(Color.semanticDanger)
                Text(error)
                    .font(.astraMono(11))
                    .foregroundStyle(.textTertiary)
                    .frame(width: 140, alignment: .trailing)
                    .lineLimit(2)
            }

        default:
            // Idle or completed — ready indicator.
            HStack(spacing: Spacing.xs) {
                StatusDot(kind: whisperService.isReady ? .ready : .idle)
                Text(String(localized: "transcription.ready"))
                    .font(.astraMono(11))
                    .foregroundStyle(Color.accent)
            }
        }
    }

    private func progressBlock(label: String, progress: Double) -> some View {
        VStack(alignment: .trailing, spacing: Spacing.xs) {
            Text(label)
                .font(.astraMono(11))
                .foregroundStyle(.textTertiary)
            ProgressHairline(progress: progress)
                .frame(width: 140)
            Text(String(format: "%.0f%%", progress * 100))
                .font(.astraMono(12, .semibold))
                .foregroundStyle(Color.accent)
        }
    }

    // MARK: - Status Computed Properties

    private var statusIcon: AstraIcon {
        switch whisperService.state {
        case .idle:                   return .mic
        case .downloadingModel:      return .download
        case .transcribing:          return .graphicEq
        case .completed:             return .checkCircle
        case .failed:                 return .warning
        }
    }

    private var statusColor: Color {
        switch whisperService.state {
        case .idle, .completed:      return .accent
        case .downloadingModel:      return .semanticWarning
        case .transcribing:          return .accent
        case .failed:                 return .semanticDanger
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
            return String(format: "large-v3-turbo %.0f%%", progress * 100)
        case .transcribing(let progress):
            return String(format: "%.0f%%", progress * 100)
        case .completed:
            let count = transcriptionResult?.segments.count ?? 0
            return String(format: String(localized: "transcription.segmentsTranscribed"), count)
        case .failed(let error):
            return error
        }
    }

    // MARK: - Recording Selector

    private var recordingSelectorSection: some View {
        AstraCard {
            VStack(spacing: Spacing.lg) {
                SectionHeader(
                    title: String(localized: "transcription.selectRecording"),
                    icon: .mic
                )

                if recordings.isEmpty {
                    EmptyStateView(
                        icon: .mic,
                        title: String(localized: "transcription.noRecordings"),
                        message: String(localized: "transcription.noRecordingsHint")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.xs) {
                            ForEach(recordings) { recording in
                                recordingRow(recording)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
            }
        }
    }

    private func recordingRow(_ recording: RecordingSession) -> some View {
        let isSelected = selectedRecording?.id == recording.id

        return Button {
            selectedRecording = recording
            startTranscription(for: recording)
        } label: {
            HStack(spacing: Spacing.md) {
                AstraAdornment(icon: .graphicEq, tint: .accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(recording.title)
                        .font(.astraBody(13, .medium))
                        .foregroundStyle(.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    HStack(spacing: Spacing.sm) {
                        Text(formatDuration(recording.duration))
                            .font(.astraMono(11))
                            .foregroundStyle(.textTertiary)

                        if let subject = recording.subjectName {
                            Text(subject)
                                .font(.astraMono(11))
                                .foregroundStyle(Color.accent.opacity(0.8))
                        }
                    }
                }

                Spacer()

                if isSelected && isTranscribing {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color.accent)
                } else {
                    AstraIconView(.chevronRight, size: 11)
                        .foregroundStyle(.textTertiary.opacity(0.5))
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.control)
                    .fill(isSelected ? Color.accentContainer : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.control)
                    .stroke(isSelected ? Color.accent.opacity(0.3) : Color.hairline.opacity(0.5), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isTranscribing)
    }

    // MARK: - Transcription Content Section

    private func transcriptionContentSection(result: TranscriptionResult) -> some View {
        VStack(spacing: Spacing.lg) {
            // Statistics row
            statisticsRow(result: result)

            // Transcription text area
            AstraCard {
                VStack(spacing: Spacing.md) {
                    // Header with edit/copy actions
                    HStack(spacing: Spacing.sm) {
                        SectionHeader(
                            title: String(localized: "transcription.transcription"),
                            icon: .notes
                        )

                        Spacer()

                        // Language badge
                        if result.language != "auto" {
                            languageBadge(result.language)
                        }

                        // Copy button
                        TagChip(
                            text: copiedToClipboard ? String(localized: "transcription.copied") : String(localized: "common.copy"),
                            isSelected: copiedToClipboard
                        ) {
                            copyToClipboard(text: editableText)
                        }

                        // Edit/Save toggle
                        TagChip(
                            text: isEditing ? String(localized: "transcription.done") : String(localized: "transcription.edit"),
                            isSelected: isEditing
                        ) {
                            withAnimation(Motion.stateChange) {
                                isEditing.toggle()
                            }
                        }
                    }

                    // Segmented transcription display
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            ForEach(Array(result.segments.enumerated()), id: \.offset) { index, segment in
                                segmentView(segment: segment, index: index)
                            }
                        }
                        .padding(Spacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.surfaceBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.card)
                                .stroke(Color.hairline, lineWidth: 1)
                        )
                    }
                    .frame(maxHeight: 400)
                }
            }
        }
    }

    private func statisticsRow(result: TranscriptionResult) -> some View {
        HStack(spacing: Spacing.md) {
            statBadge(
                icon: .notes,
                value: "\(result.wordCount)",
                label: String(localized: "transcription.words")
            )
            statBadge(
                icon: .schedule,
                value: result.segments.first.map { formatTime($0.startTime) } ?? "--:--",
                label: String(localized: "transcription.start")
            )
            statBadge(
                icon: .history,
                value: result.segments.last.map { formatTime($0.endTime) } ?? "--:--",
                label: String(localized: "transcription.end")
            )
            statBadge(
                icon: .barChart,
                value: String(format: "%.1f%%", result.confidence * 100),
                label: String(localized: "transcription.confidence")
            )
            Spacer()
        }
    }

    private func statBadge(icon: AstraIcon, value: String, label: String) -> some View {
        HStack(spacing: Spacing.sm) {
            AstraIconView(icon, size: 12)
                .foregroundStyle(Color.accent)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.astraMono(14, .semibold))
                    .foregroundStyle(.textPrimary)
                Text(label)
                    .font(TypeScale.micro)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .foregroundStyle(.textTertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.control)
                .stroke(Color.hairline, lineWidth: 1)
        )
    }

    private func segmentView(segment: TranscriptionSegment, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: Spacing.sm) {
                // Segment index badge
                Text(String(format: "%02d", index + 1))
                    .font(.astraMono(10, .bold))
                    .foregroundStyle(Color.accent)
                    .frame(width: 28, height: 20)
                    .background(Color.accentContainer)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.micro))

                // Timestamp
                Text("\(formatTime(segment.startTime)) - \(formatTime(segment.endTime))")
                    .font(.astraMono(10))
                    .foregroundStyle(.textTertiary)

                // Confidence
                Text(String(format: "%.0f%%", segment.confidence * 100))
                    .font(.astraMono(10))
                    .foregroundStyle(
                        segment.confidence > 0.8 ? Color.accent.opacity(0.7) : Color.semanticWarning.opacity(0.8)
                    )

                // Speaker badge (if available)
                if let speakerID = segment.speakerID {
                    Text(String(format: String(localized: "transcription.speaker"), speakerID))
                        .font(.astraBody(10, .medium))
                        .foregroundStyle(speakerColor(for: speakerID))
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 2)
                        .background(speakerColor(for: speakerID).opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            // Segment text
            Text(segment.text)
                .font(TypeScale.bodyLarge)
                .foregroundStyle(.textPrimary)
                .lineSpacing(4)
        }
    }

    private func languageBadge(_ code: String) -> some View {
        let name = WhisperService.supportedLanguages.first(where: { $0.code == code })?.name ?? code.uppercased()
        return TagChip(text: name, isSelected: true)
    }

    // MARK: - Export Section

    private var exportSection: some View {
        AstraCard {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                SectionHeader(
                    title: String(localized: "transcription.exportOptions"),
                    icon: .share
                )

                HStack(spacing: Spacing.md) {
                    // Primary: Generate Note
                    AstraButton(
                        title: String(localized: "transcription.generateNote"),
                        icon: .autoAwesome,
                        style: .primary
                    ) {
                        // TODO: Navigate to note generation with transcription result.
                    }

                    AstraButton(
                        title: String(localized: "transcription.copyText"),
                        style: .secondary
                    ) {
                        if let result = transcriptionResult {
                            copyToClipboard(text: result.fullText)
                        }
                    }

                    AstraButton(
                        title: String(localized: "transcription.markdown"),
                        style: .secondary
                    ) {
                        exportAsMarkdown()
                    }

                    AstraButton(
                        title: String(localized: "transcription.srt"),
                        style: .secondary
                    ) {
                        exportAsSRT()
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func startTranscription(for recording: RecordingSession) {
        guard !isTranscribing else { return }
        isTranscribing = true

        guard let filePath = recording.filePath?.path else {
            isTranscribing = false
            return
        }
        let audioURL = URL(fileURLWithPath: filePath)

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

        if result.language != "auto" {
            md += "**Language:** \(result.language)\n"
        }
        md += "**Word Count:** \(result.wordCount)\n"
        md += "**Confidence:** \(String(format: "%.1f%%", result.confidence * 100))\n\n---\n\n"

        for (index, segment) in result.segments.enumerated() {
            let startTime = formatTimeSRT(segment.startTime)
            let endTime = formatTimeSRT(segment.endTime)
            md += "**[\(startTime) -> \(endTime)]** \(segment.text)\n\n"
        }

        md += "\n---\n*Generated by AstraNotes \(formattedDateNow)*\n"
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

    /// Deterministic color for a speaker ID, drawn from the semantic palette.
    private func speakerColor(for speakerID: Int) -> Color {
        let palette: [Color] = [
            .accent,
            Color(light: "#5A5CA8", dark: "#A2A4E8"), // indigo
            Color(light: "#2E7D6E", dark: "#6FC3B2"), // teal
            Color(light: "#B4574E", dark: "#D98A83"), // rose
            Color(light: "#8A6D2F", dark: "#C9A85C"), // gold
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
}
