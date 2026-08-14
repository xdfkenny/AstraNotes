// AudioService.swift — AstraNotes
// AVAudioEngine-based audio recording service optimized for Whisper transcription.
// 16 kHz mono output, real-time waveform visualization, silence detection, .m4a file output.

import SwiftUI
import AVFoundation

// MARK: - Audio Service

@Observable
final class AudioService {

    // MARK: - Recording State

    enum RecordingState: Equatable {
        case idle
        case recording
        case paused
        case stopped
    }

    var state: RecordingState = .idle

    // MARK: - Public Observable Properties

    /// Elapsed recording time in seconds (accumulates across pause/resume).
    var currentTime: TimeInterval = 0

    /// Downsampled waveform data for UI visualization (up to 64 samples).
    var waveformData: [Float] = []

    /// Current average audio power level in dB (range roughly -160..0).
    var averagePower: Float = -160

    /// Human-readable error message when a recording operation fails.
    var errorMessage: String?

    // MARK: - Private State

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var outputFileURL: URL?
    private var timer: Timer?
    private var silenceTimer: Timer?
    private var isSilent: Bool = false

    /// Format converter node that bridges the hardware input format to 16 kHz mono.
    private var converterNode: AVAudioMixerNode?

    // MARK: - Configuration Constants

    private let sampleRate: Double = 16000
    private let channels: UInt32 = 1
    private let bufferSize: AVAudioFrameCount = 1024

    /// Power level (dB) below which audio is considered silence.
    private let silenceThreshold: Float = -50

    /// Seconds of continuous silence before auto-pause triggers.
    private let silenceDuration: TimeInterval = 10

    // MARK: - Recording Lifecycle

    /// Starts a new recording session and writes to Documents/AstraNotes/Recordings/<fileName>.m4a.
    /// - Parameter fileName: Base file name without extension.
    /// - Throws: `AudioError` when the audio device is unavailable or engine fails to start.
    func startRecording(fileName: String) async throws {
        // Tear down any previous session first.
        stopRecording()

        // ── Audio Engine Setup ──────────────────────────────────────────────
        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine

        let inputNode = audioEngine.inputNode
        guard let inputFormat = inputNode.outputFormat(forBus: 0) else {
            throw AudioError.deviceNotAvailable
        }

        // Target format: 16 kHz mono (optimal for Whisper).
        guard let outputFormat = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: channels
        ) else {
            throw AudioError.deviceNotAvailable
        }

        // Use a mixer node to convert from hardware format to Whisper-optimized format.
        let converterNode = AVAudioMixerNode()
        audioEngine.attach(converterNode)
        audioEngine.connect(inputNode, to: converterNode, format: inputFormat)
        audioEngine.connect(converterNode, to: audioEngine.mainMixerNode, format: outputFormat)
        self.converterNode = converterNode

        // ── Tap on converter output for waveform + power metering ─────────
        converterNode.installTap(onBus: 0, bufferSize: bufferSize, format: outputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }

            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)

            // Calculate RMS-based average power in dB.
            var sumSquares: Float = 0
            for i in 0..<frameLength {
                let sample = channelData[i]
                sumSquares += sample * sample
            }
            let rms = sqrt(sumSquares / Float(max(1, frameLength)))
            let avgPower = 20 * log10(rms + 0.0001)

            // Downsample waveform to ~64 bars for UI display.
            let targetBars = 64
            let step = max(1, frameLength / targetBars)
            var samples: [Float] = []
            samples.reserveCapacity(targetBars)
            var peakInBucket: Float = 0
            for i in 0..<frameLength {
                peakInBucket = max(peakInBucket, abs(channelData[i]))
                if (i + 1) % step == 0 || i == frameLength - 1 {
                    samples.append(min(1.0, peakInBucket * 5))
                    peakInBucket = 0
                }
            }

            // ── Main-actor state update ──────────────────────────────────────
            Task { @MainActor in
                self.waveformData = samples
                self.averagePower = avgPower

                // Silence detection with hysteresis.
                let currentlySilent = avgPower < self.silenceThreshold
                if currentlySilent != self.isSilent {
                    self.isSilent = currentlySilent
                    self.handleSilenceChange(isSilent: currentlySilent)
                }
            }
        }

        // ── Create output file ─────────────────────────────────────────────
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let outputDir = documentsPath
            .appendingPathComponent("AstraNotes")
            .appendingPathComponent("Recordings")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let fileURL = outputDir.appendingPathComponent("\(fileName).m4a")
        outputFileURL = fileURL

        audioFile = try AVAudioFile(
            forWriting: fileURL,
            settings: outputFormat.settings
        )

        // ── Secondary tap on input node to capture raw PCM for file writing ─
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self,
                  let audioFile = self.audioFile,
                  let outputFormat = self.converterNode?.outputFormat(forBus: 0) else { return }

            // Convert buffer to output format before writing.
            guard let converter = AVAudioConverter(from: buffer.format, to: outputFormat) else { return }
            let inputFrameCount = buffer.frameLength
            let outputFrameCount = AVAudioFrameCount(
                Double(inputFrameCount) * outputFormat.sampleRate / buffer.format.sampleRate
            )
            let convertedBuffer = AVAudioPCMBuffer(
                format: outputFormat,
                frameCapacity: outputFrameCount
            )

            var error: NSError?
            let status = converter.convert(
                to: convertedBuffer,
                error: &error
            ) { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return inputFrameCount
            }

            if status != .error {
                try? audioFile.write(from: convertedBuffer)
            }
        }

        // ── Start engine ───────────────────────────────────────────────────
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            errorMessage = String(format: String(localized: "error.audioSessionFailedDetail"), error.localizedDescription)
            state = .error
            return
        }
        
        // Request microphone permission on iOS
        let permissionStatus = await session.requestPermission(for: .record)
        guard permissionStatus == .granted else {
            errorMessage = String(localized: "error.microphoneDenied")
            state = .error
            return
        }
        #endif

        audioEngine.prepare()
        try audioEngine.start()

        state = .recording
        errorMessage = nil
        isSilent = false
        startTimer()
    }

    /// Pauses an active recording. The timer and audio engine are paused.
    func pauseRecording() {
        guard state == .recording else { return }
        audioEngine?.pause()
        state = .paused
        stopTimer()
    }

    /// Resumes a paused recording.
    func resumeRecording() throws {
        guard state == .paused else { return }
        try audioEngine?.start()
        state = .recording
        startTimer()
    }

    /// Stops the current recording, tears down the audio engine, and returns
    /// the URL of the output .m4a file (or nil if no recording was in progress).
    @discardableResult
    func stopRecording() -> URL? {
        // Remove taps before stopping to avoid orphaned callbacks.
        if let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
            converterNode?.removeTap(onBus: 0)
        }

        audioEngine?.stop()
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
        audioEngine = nil
        converterNode = nil
        stopTimer()
        stopSilenceTimer()

        let url = outputFileURL
        outputFileURL = nil
        audioFile = nil

        state = .idle
        currentTime = 0
        waveformData = []
        averagePower = -160
        isSilent = false
        errorMessage = nil

        return url
    }

    // MARK: - Timer Management

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.currentTime += 0.1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Silence Detection

    private func handleSilenceChange(isSilent: Bool) {
        if isSilent {
            // Start a timer that will auto-pause after the silence duration.
            silenceTimer = Timer.scheduledTimer(
                withTimeInterval: silenceDuration,
                repeats: false
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.pauseRecording()
                }
            }
        } else {
            // Sound detected — cancel the silence timer.
            stopSilenceTimer()
            // Auto-resume if we were paused due to silence.
            if state == .paused {
                try? resumeRecording()
            }
        }
    }

    private func stopSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = nil
    }

    // MARK: - Formatted Time

    /// Returns the current recording time formatted as "M:SS" or "H:MM:SS".
    var formattedTime: String {
        let total = Int(currentTime)
        let hours   = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Returns the file size of the last recording in human-readable form.
    func fileSizeString(for url: URL) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        guard let size = try? FileManager.default.attributesOfItem(
            atPath: url.path
        )[.size] as? Int64 else {
            return "Unknown"
        }
        return formatter.string(fromByteCount: size)
    }

    // MARK: - Audio Error

    enum AudioError: LocalizedError {
        case deviceNotAvailable
        case recordingFailed(String)

        var errorDescription: String? {
            switch self {
            case .deviceNotAvailable:
                return String(localized: "error.audioInputUnavailable")
            case .recordingFailed(let message):
                return String(format: String(localized: "error.recordingFailed"), message)
            }
        }
    }
}
