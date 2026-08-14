// WhisperService.swift — AstraNotes
// Whisper transcription service wrapping WhisperKit (CoreML).
// Uses large-v3-turbo model. Supports English, Spanish, Chinese (auto-detect).
// Provides progress reporting, word-level timestamps, and chunking for long recordings.

import Foundation
import AVFoundation
import WhisperKit

// MARK: - Whisper Service

@Observable
final class WhisperService {

    // MARK: - Transcription State

    enum TranscriptionState: Equatable {
        case idle
        case downloadingModel(progress: Double)
        case transcribing(progress: Double)
        case completed
        case failed(error: String)

        // Equatable conformance ignores error details for SwiftUI change detection.
        static func == (lhs: TranscriptionState, rhs: TranscriptionState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.downloadingModel, .downloadingModel): return true
            case (.transcribing, .transcribing): return true
            case (.completed, .completed): return true
            case (.failed, .failed): return true
            default: return false
            }
        }
    }

    var state: TranscriptionState = .idle

    /// The most recent text segment as it is being transcribed.
    var currentSegment: String = ""

    /// All completed transcription segments.
    var segments: [TranscriptionSegment] = []

    /// Whether the Whisper model is downloaded and ready for transcription.
    var isReady: Bool {
        transcriber != nil
    }

    /// Whether the model has been downloaded at least once (persisted check).
    var isModelDownloaded: Bool {
        // WhisperKit stores models in the documents directory.
        // We use the public API to check if the model is available.
        let modelPath = WhisperKit.modelPath(for: modelSize, computeUnits: .cpuAndNeuralEngine)
        return FileManager.default.fileExists(atPath: modelPath.path)
    }

    // MARK: - Private State

    private var transcriber: WhisperKit?

    /// The WhisperKit model variant to use.
    private let modelSize = "large-v3-turbo"

    /// Default chunk duration in seconds for splitting long recordings.
    private let defaultChunkDuration: TimeInterval = 1800 // 30 minutes

    // MARK: - Supported Languages

    /// Languages supported by this service instance. Extend as needed.
    static let supportedLanguages: [(code: String, name: String)] = [
        ("en", "English"),
        ("es", "Spanish"),
        ("zh", "Chinese (Mandarin)"),
        ("fr", "French"),
        ("de", "German"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("pt", "Portuguese"),
        ("ar", "Arabic"),
        ("hi", "Hindi"),
        ("ru", "Russian"),
        ("it", "Italian"),
    ]

    // MARK: - Model Initialization

    /// Downloads (if needed) and initializes the WhisperKit model.
    /// Must be called before transcribing, or `transcribe` will call it lazily.
    func initializeModel() async {
        state = .downloadingModel(progress: 0)

        do {
            let config = WhisperKitConfig(
                model: modelSize,
                computeOptions: .init(
                    audioEncoderCompute: .cpuAndNeuralEngine,
                    textDecoderCompute: .cpuAndNeuralEngine
                ),
                verbose: true,
                language: nil, // Auto-detect language
                task: .transcribe,
                prefill: false
            )

            transcriber = try await WhisperKit(config)
            state = .idle
        } catch {
            state = .failed(
                error: String(format: String(localized: "error.whisperInitFailed"), error.localizedDescription)
            )
        }
    }

    /// Deletes the downloaded model files to free disk space.
    func deleteModel() async throws {
        guard let transcriber = transcriber else { return }
        self.transcriber = nil

        let modelPath = WhisperKit.modelPath(for: modelSize, computeUnits: .cpuAndNeuralEngine)
        if FileManager.default.fileExists(atPath: modelPath.path) {
            try FileManager.default.removeItem(at: modelPath)
        }

        state = .idle
    }

    // MARK: - Transcription

    /// Transcribes a single audio file and returns the full result.
    /// - Parameters:
    ///   - audioURL: File URL pointing to the audio file (.m4a, .wav, .mp3, etc.)
    ///   - language: Optional BCP-47 language code. Pass nil for auto-detection.
    /// - Returns: A `TranscriptionResult` with full text, segments, and metadata.
    /// - Throws: `WhisperError` if the model is not ready or transcription fails.
    func transcribe(audioURL: URL, language: String? = nil) async throws -> TranscriptionResult {
        // Lazily initialize the model if not yet ready.
        if transcriber == nil {
            await initializeModel()
        }
        guard let transcriber = transcriber else {
            throw WhisperError.modelNotReady
        }

        state = .transcribing(progress: 0)
        segments = []
        currentSegment = ""

        let transcriptionResult: TranscriptionResult
        do {
            let whisperResult = try await transcriber.transcribeAudioURL(
                audioURL,
                decodeOptions: .init(
                    language: language,
                    task: .transcribe,
                    wordTimestamps: true
                )
            )

            // Convert WhisperKit segments to our model.
            let convertedSegments = whisperResult.allSegments.compactMap { segment -> TranscriptionSegment in
                TranscriptionSegment(
                    speakerID: nil,
                    text: segment.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    startTime: segment.start,
                    endTime: segment.end,
                    confidence: segment.logProb,
                    words: segment.words.map { word in
                        WordTimestamp(
                            word: word.word,
                            startTime: word.start,
                            endTime: word.end,
                            confidence: word.logProb
                        )
                    }
                )
            }

            // Calculate overall confidence.
            let totalLogProb = convertedSegments.map(\.confidence).reduce(0, +)
            let avgConfidence = convertedSegments.isEmpty
                ? 0
                : totalLogProb / Double(convertedSegments.count)

            transcriptionResult = TranscriptionResult(
                fullText: whisperResult.text,
                segments: convertedSegments,
                language: language ?? whisperResult.language ?? "auto",
                confidence: avgConfidence,
                wordCount: whisperResult.text.split(separator: " ").count
            )

        } catch {
            state = .failed(error: String(format: String(localized: "error.whisperFailedDetail"), error.localizedDescription))
            throw WhisperError.transcriptionFailed(error.localizedDescription)
        }

        // Update state and publish segments.
        state = .completed
        segments = transcriptionResult.segments
        return transcriptionResult
    }

    // MARK: - Long Recording Chunking

    /// Transcribes recordings longer than `chunkDuration` by splitting them into
    /// manageable segments, transcribing each individually, and merging results
    /// with correctly adjusted timestamps.
    /// - Parameters:
    ///   - audioURL: File URL pointing to the audio file.
    ///   - language: Optional BCP-47 language code. Pass nil for auto-detection.
    ///   - chunkDuration: Duration in seconds for each chunk (default: 1800 = 30 min).
    /// - Returns: A combined `TranscriptionResult` spanning the full recording.
    func transcribeLongRecording(
        audioURL: URL,
        language: String? = nil,
        chunkDuration: TimeInterval = 1800
    ) async throws -> TranscriptionResult {
        let asset = AVAsset(url: audioURL)
        let duration = try await asset.load(.duration)
        let totalSeconds = CMTimeGetSeconds(duration)

        // No chunking needed for short recordings.
        guard totalSeconds > chunkDuration else {
            return try await transcribe(audioURL: audioURL, language: language)
        }

        var allSegments: [TranscriptionSegment] = []
        var fullText = ""
        var totalWordCount = 0
        var totalConfidence: Double = 0
        var segmentCount = 0

        let chunkCount = Int(ceil(totalSeconds / chunkDuration))

        for chunkIndex in 0..<chunkCount {
            let startTime = Double(chunkIndex) * chunkDuration
            let endTime = min(Double(chunkIndex + 1) * chunkDuration, totalSeconds)

            state = .transcribing(
                progress: Double(chunkIndex) / Double(chunkCount)
            )

            // Extract chunk to a temporary file.
            let chunkURL = try extractChunk(
                from: audioURL,
                start: startTime,
                end: endTime
            )

            // Transcribe the chunk.
            let chunkResult = try await transcribe(audioURL: chunkURL, language: language)

            // Adjust all timestamps by the chunk offset.
            let adjustedSegments = chunkResult.segments.map { segment -> TranscriptionSegment in
                var adjusted = segment
                adjusted.startTime += startTime
                adjusted.endTime += startTime

                // Adjust word-level timestamps too.
                if !adjusted.words.isEmpty {
                    adjusted.words = adjusted.words.map { word -> WordTimestamp in
                        var w = word
                        w.startTime += startTime
                        w.endTime += startTime
                        return w
                    }
                }

                return adjusted
            }

            allSegments.append(contentsOf: adjustedSegments)

            // Merge text with a paragraph break between chunks.
            if fullText.isEmpty {
                fullText = chunkResult.fullText
            } else {
                fullText += "\n\n" + chunkResult.fullText
            }

            totalWordCount += chunkResult.wordCount
            totalConfidence += chunkResult.confidence
            segmentCount += 1

            // Clean up temporary chunk file.
            try? FileManager.default.removeItem(at: chunkURL)
        }

        state = .completed

        let avgConfidence = segmentCount > 0 ? totalConfidence / Double(segmentCount) : 0

        return TranscriptionResult(
            fullText: fullText,
            segments: allSegments,
            language: language ?? "auto",
            confidence: avgConfidence,
            wordCount: totalWordCount
        )
    }

    // MARK: - Chunk Extraction

    /// Extracts a time range from an audio file and writes it to a temporary .m4a file.
    private func extractChunk(from url: URL, start: Double, end: Double) throws -> URL {
        let asset = AVAsset(url: url)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("whisper_chunk_\(Int(start))_\(Int(end)).m4a")

        // Remove any pre-existing file at the same path.
        try? FileManager.default.removeItem(at: outputURL)

        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw WhisperError.chunkExtractionFailed
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.timeRange = CMTimeRange(
            start: CMTime(seconds: start, preferredTimescale: 44100),
            end: CMTime(seconds: end, preferredTimescale: 44100)
        )

        exportSession.exportAsynchronously()

        // Busy-wait until export completes (runs on background thread via caller).
        while exportSession.status == .exporting {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }

        guard exportSession.status == .completed else {
            let message = exportSession.error?.localizedDescription ?? "Unknown export error"
            throw WhisperError.chunkExtractionFailed
        }

        return outputURL
    }

    // MARK: - Whisper Error

    enum WhisperError: LocalizedError {
        case modelNotReady
        case chunkExtractionFailed
        case transcriptionFailed(String)
        case unsupportedFormat
        case fileTooShort

        var errorDescription: String? {
            switch self {
            case .modelNotReady:
                return String(localized: "error.whisperNotReady")
            case .chunkExtractionFailed:
                return String(localized: "error.chunkExtractionFailed")
            case .transcriptionFailed(let message):
                return String(format: String(localized: "error.whisperFailedDetail"), message)
            case .unsupportedFormat:
                return String(localized: "error.unsupportedAudioFormat")
            case .fileTooShort:
                return String(localized: "error.audioFileTooShort")
            }
        }
    }
}
