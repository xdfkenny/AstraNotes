//
//  StatusDot.swift
//  AstraNotes
//
//  Semantic state dot. NEVER decorative. Always paired with a label.
//  Recording = danger + pulse (semantic live state, reduce-motion aware).
//

import SwiftUI

enum StatusKind {
    case idle
    case ready     // success
    case processing // warning
    case recording  // danger + pulse
    case error      // danger, static

    var color: Color {
        switch self {
        case .idle: return .textTertiary
        case .ready: return .semanticSuccess
        case .processing: return .semanticWarning
        case .recording, .error: return .semanticDanger
        }
    }

    var isPulsing: Bool { self == .recording }
}

struct StatusDot: View {
    let kind: StatusKind
    var label: String?

    @State private var pulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(kind.color)
                .frame(width: 8, height: 8)
                .opacity(dotOpacity)
                .animation(
                    kind.isPulsing && !reduceMotion
                        ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                        : .default,
                    value: pulsing
                )
            if let label {
                Text(label)
                    .font(TypeScale.caption)
                    .foregroundStyle(.textSecondary)
            }
        }
        .onAppear { pulsing = kind.isPulsing }
        .onChange(of: kind) { _, newKind in pulsing = newKind.isPulsing }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label ?? statusAccessibilityLabel)
    }

    private var dotOpacity: Double {
        kind.isPulsing && pulsing && !reduceMotion ? 0.35 : 1
    }

    private var statusAccessibilityLabel: String {
        switch kind {
        case .idle: return "Idle"
        case .ready: return "Ready"
        case .processing: return "Processing"
        case .recording: return "Recording"
        case .error: return "Error"
        }
    }
}
