//
//  TagChip.swift
//  AstraNotes
//
//  Capsule chip for tags and metadata. Selected state uses accent container.
//

import SwiftUI

struct TagChip: View {
    let text: String
    var isSelected: Bool = false
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) { chip }
                    .buttonStyle(.plain)
            } else {
                chip
            }
        }
    }

    private var chip: some View {
        Text(text)
            .font(.astraBody(11, .medium))
            .foregroundStyle(isSelected ? Color.accent : Color.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isSelected ? Color.accentContainer : Color.surface)
            .overlay(
                Capsule().stroke(
                    isSelected ? Color.accent.opacity(0.5) : Color.hairline,
                    lineWidth: 1
                )
            )
            .clipShape(Capsule())
    }
}

/// HL / SL badge. Uppercase 10pt, micro radius, max 3 chars.
struct LevelBadge: View {
    let level: String // "HL" or "SL"

    var body: some View {
        Text(level.uppercased())
            .font(.astraBody(10, .semibold))
            .tracking(0.6)
            .foregroundStyle(level == "HL" ? Color.accent : Color.textSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(level == "HL" ? Color.accentContainer : Color.hairline.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: Radius.micro))
    }
}

/// Subject roundel: muted group color circle + Material glyph (sidebar rows, pickers).
struct SubjectRoundel: View {
    let icon: AstraIcon
    let group: Int

    var body: some View {
        AstraIconView(icon, size: 13)
            .frame(width: 28, height: 28)
            .background(Color.groupContainer(group))
            .foregroundStyle(Color.groupColor(group))
            .clipShape(Circle())
    }
}
