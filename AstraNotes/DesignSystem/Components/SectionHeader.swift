//
//  SectionHeader.swift
//  AstraNotes
//
//  Icon + title + optional count chip, hairline divider below.
//  Micro labels are rationed (max 1 per 3 sections); this header uses
//  a neutral SF Symbol instead of uppercase tracking labels.
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    var icon: AstraIcon?
    var count: Int?
    var tint: Color = .textPrimary

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon {
                AstraIconView(icon, size: 12)
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(TypeScale.heading)
                .foregroundStyle(.textPrimary)
            if let count {
                Text(String(count))
                    .font(.astraMono(11, .medium))
                    .foregroundStyle(.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Color.hairline)
                    .clipShape(Capsule())
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.sm)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

/// Rationed micro label (uppercase, tracked). Max 1 per 3 sections.
struct MicroLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(TypeScale.micro)
            .tracking(0.8)
            .foregroundStyle(.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
