//
//  SkeletonView.swift
//  AstraNotes
//
//  Structural skeleton for AI generation loading. Shimmer via opacity
//  only (GPU-safe), staggered. Matches the final note structure:
//  title bar, summary lines, formula block, diagram block. No spinners.
//

import SwiftUI

struct SkeletonView: View {
    var blockCount: Int = 3

    @State private var shimmer = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Title bar
            RoundedRectangle(cornerRadius: Radius.control)
                .fill(Color.hairline)
                .frame(width: 180, height: 22)

            // Summary block
            VStack(alignment: .leading, spacing: Spacing.sm) {
                skeletonLine(width: 320)
                skeletonLine(width: 420)
                skeletonLine(width: 260)
            }

            // Formula block (accent-tinted, signals math content)
            RoundedRectangle(cornerRadius: Radius.control)
                .fill(Color.accent.opacity(0.10))
                .frame(height: 44)

            // Diagram block (2:3 ratio, mermaid placeholder)
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(Color.hairline)
                .frame(height: 140)

            // Remaining blocks
            ForEach(0..<max(blockCount - 2, 0), id: \.self) { _ in
                RoundedRectangle(cornerRadius: Radius.control)
                    .fill(Color.hairline)
                    .frame(height: 64)
            }
        }
        .frame(maxWidth: LayoutTokens.contentMaxWidth, alignment: .leading)
        .opacity(shimmer ? 0.45 : 1)
        .animation(
            reduceMotion
                ? nil
                : .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
            value: shimmer
        )
        .onAppear { shimmer = true }
        .accessibilityLabel("Generating notes")
    }

    private func skeletonLine(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Radius.micro)
            .fill(Color.hairline)
            .frame(width: width, height: 10)
    }
}

/// Transcription / export progress: hairline that fills with progress.
/// Width-driven with 150ms state change. Replaces filled-track bars.
struct ProgressHairline: View {
    let progress: Double // 0...1

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.hairline)
                Rectangle()
                    .fill(Color.accent)
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 2)
        .clipShape(Capsule())
        .animation(.easeOut(duration: 0.15), value: progress)
        .accessibilityValue(Text("\(Int(progress * 100)) percent"))
    }
}
