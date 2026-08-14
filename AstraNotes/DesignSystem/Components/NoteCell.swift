//
//  NoteCell.swift
//  AstraNotes
//
//  List row for notes: subject roundel, title, mono metadata
//  (duration, date). Used by Library, Dashboard, and Recent Notes.
//

import SwiftUI

struct NoteCell: View {
    let title: String
    let group: Int
    let subjectIcon: AstraIcon
    let subjectName: String
    let dateText: String
    let durationText: String
    var isSelected: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                SubjectRoundel(icon: subjectIcon, group: group)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(TypeScale.subheading)
                        .foregroundStyle(isSelected ? Color.accent : Color.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: Spacing.sm) {
                        Text(subjectName)
                            .font(TypeScale.caption)
                            .foregroundStyle(.textSecondary)
                        Spacer(minLength: 8)
                        Text(dateText)
                            .font(.astraMono(10))
                            .foregroundStyle(.textTertiary)
                        Text(durationText)
                            .font(.astraMono(10))
                            .foregroundStyle(.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    AstraIconView(.check, size: 11)
                        .foregroundStyle(Color.accent)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.accentContainer : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Radius.control))
        .overlay(alignment: .leading) {
            if isSelected {
                Rectangle()
                    .fill(Color.accent)
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 1.5))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}
