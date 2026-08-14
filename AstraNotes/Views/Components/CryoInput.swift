import SwiftUI

// MARK: - CryoInput
// A frost-styled text input field with rounded corners, a subtle border,
// and an animated glow effect on focus. Supports both single-line
// `TextField` and multi-line `TextEditor` modes.

struct CryoInput: View {
    let placeholder: String
    @Binding var text: String
    let manager: ThemeManager
    var isMultiline: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        if isMultiline {
            multiLineEditor
        } else {
            singleLineField
        }
    }

    // MARK: - Single Line

    private var singleLineField: some View {
        TextField(placeholder, text: $text)
            .font(.system(size: 15))
            .foregroundColor(CryoColors.foreground(manager))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(CryoColors.backgroundWarm(manager))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused
                            ? CryoColors.accent(manager)
                            : CryoColors.border(manager),
                        lineWidth: isFocused ? 2 : 1.5
                    )
            )
            .shadow(
                color: isFocused ? CryoColors.shadowGlow(manager) : .clear,
                radius: isFocused ? 8 : 0
            )
            .focused($isFocused)
    }

    // MARK: - Multi Line

    private var multiLineEditor: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder overlay (only visible when text is empty and not focused)
            if text.isEmpty && !isFocused {
                Text(placeholder)
                    .font(.system(size: 15))
                    .foregroundColor(CryoColors.foregroundMuted(manager).opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .font(.system(size: 15))
                .foregroundColor(CryoColors.foreground(manager))
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(CryoColors.backgroundWarm(manager))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused
                                ? CryoColors.accent(manager)
                                : CryoColors.border(manager),
                            lineWidth: isFocused ? 2 : 1.5
                        )
                )
                .shadow(
                    color: isFocused ? CryoColors.shadowGlow(manager) : .clear,
                    radius: isFocused ? 8 : 0
                )
                .focused($isFocused)
        }
    }
}
