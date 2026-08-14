//
//  WaveformView.swift
//  AstraNotes
//
//  Live waveform from real AVAudioEngine amplitude data. 60 bars, spring
//  physics (0.15s response). Recording bars tint danger; idle = 3pt baseline.
//  Never fake data: amplitudes come from the audio tap only.
//

import SwiftUI

struct WaveformView: View {
    /// Amplitude levels, normalized 0...1, updated by AudioService (~10Hz).
    let levels: [Double]
    /// Recording = danger bars, else tertiary (dimmed when paused).
    var isActive: Bool = false
    var barCount: Int = 60

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { _ in
            HStack(alignment: .center, spacing: 2.5) {
                ForEach(0..<barCount, id: \.self) { index in
                    Capsule()
                        .fill(barColor(index: index))
                        .frame(width: 3, height: barHeight(index: index))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isActive ? "Audio waveform, recording" : "Audio waveform")
        }
    }

    private func level(at index: Int) -> Double {
        guard !levels.isEmpty else { return 0 }
        // Map the audio frame index into the provided level history.
        let idx = index * levels.count / barCount
        return levels[min(idx, levels.count - 1)]
    }

    private func barHeight(index: Int) -> CGFloat {
        let base: CGFloat = isActive ? 4 : 3
        let peak = max(level(at: index) * 36, base)
        return peak
    }

    private func barColor(index: Int) -> Color {
        if !isActive { return Color.hairline }
        let l = level(at: index)
        // Quieter bars slightly transparent: depth without decorative effects.
        return Color.semanticDanger.opacity(0.55 + (l * 0.45))
    }
}

/// Static summary waveform for note cells and the dashboard hero (real data).
struct StaticWaveform: View {
    let levels: [Double]

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<min(levels.count, 48), id: \.self) { index in
                Capsule()
                    .fill(Color.textTertiary.opacity(0.7))
                    .frame(width: 2, height: max(Double(levels[index]) * 24, 2))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 28, alignment: .center)
        .accessibilityHidden(true)
    }
}
