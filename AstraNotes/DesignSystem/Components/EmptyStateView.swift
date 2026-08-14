//
//  EmptyStateView.swift
//  AstraNotes
//
//  Composed empty state: 48pt symbol in tinted roundel, display title,
//  one secondary line, one primary CTA. Never a bare "No items" label.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: AstraIcon
    let title: String
    let message: String
    var ctaTitle: String?
    var ctaAction: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            AstraIconView(icon, size: 24)
                .frame(width: 64, height: 64)
                .background(Color.accent.opacity(0.10))
                .foregroundStyle(Color.accent)
                .clipShape(Circle())

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(TypeScale.display)
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(TypeScale.body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
                    .lineLimit(2)
            }

            if let ctaTitle, let ctaAction {
                AstraButton(title: ctaTitle, style: .primary, action: ctaAction)
            }
        }
        .padding(.vertical, Spacing.xxxl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
