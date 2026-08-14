//
//  AstraTextField.swift
//  AstraNotes
//
//  Styled text field: surface background, control radius, hairline border,
//  accent focus ring. Label sits above, never as placeholder.
//

import SwiftUI

struct AstraTextField: View {
    let title: String?
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let title {
                Text(title)
                    .font(TypeScale.caption)
                    .foregroundStyle(.textSecondary)
            }
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .font(TypeScale.body)
            .padding(.horizontal, Spacing.md)
            .frame(height: 32)
            .background(Color.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.control)
                    .stroke(isFocused ? Color.accent.opacity(0.6) : Color.hairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.control))
            .focused($isFocused)
        }
    }
}
