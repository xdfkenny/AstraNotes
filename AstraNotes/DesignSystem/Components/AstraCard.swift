//
//  AstraCard.swift
//  AstraNotes
//
//  Double-bezel card: outer hairline shell (1pt padding, +2 radius) wrapping
//  an inner content surface. Optional leading adornment (subject roundel,
//  tinted symbol). Hairlines over shadows per design system.
//

import SwiftUI

struct AstraCard<Content: View>: View {
    /// Optional accent tint for the inner surface (e.g. hero cells at 8%).
    var tint: Color = .clear
    /// Becomes interactive when set (hover + press feedback).
    var isSelectable: Bool = false
    var onTap: (() -> Void)?
    @ViewBuilder var content: Content

    @State private var isHovering = false
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) { shell }
                    .buttonStyle(.plain)
            } else {
                shell
            }
        }
    }

    private var shell: some View {
        content
            .padding(Layout.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint == .clear ? AnyShapeStyle(Color.surface) : AnyShapeStyle(tint))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.cardInner)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.cardInner))
            .padding(1)
            .background(
                Color.surface
                    .overlay(RoundedRectangle(cornerRadius: Radius.card).stroke(Color.hairline, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.card))
            )
            .scaleEffect(isPressed && !reduceMotion ? Motion.pressScale : 1)
            .animation(.easeOut(duration: Motion.pressDuration), value: isPressed)
            #if os(macOS)
            .onHover { hovering in
                withAnimation(Motion.stateChange) { isHovering = hovering }
            }
            #endif
            .simultaneousGesture(
                isSelectable || onTap != nil
                    ? DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                    : nil
            )
    }

    private var borderColor: Color {
        isHovering ? Color.accent.opacity(0.40) : Color.hairline
    }
}

/// Leading adornment: 28pt tinted circle with a Material glyph (subject roundels).
struct AstraAdornment: View {
    let icon: AstraIcon
    var tint: Color = .accent

    var body: some View {
        AstraIconView(icon, size: 13)
            .frame(width: 28, height: 28)
            .background(tint.opacity(0.14))
            .foregroundStyle(tint)
            .clipShape(Circle())
    }
}
