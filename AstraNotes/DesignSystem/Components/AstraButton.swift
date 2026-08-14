//
//  AstraButton.swift
//  AstraNotes
//
//  Button system: pill primary with nested trailing icon, secondary material.
//  Press physics: scale 0.97 @ 100ms, release 200ms. Labels max 3 words.
//  Icons are Google Material Symbols glyphs (AstraIconView).
//

import SwiftUI

/// Primary action: accent pill fill, onAccent text, optional nested trailing icon.
struct AstraButton: View {
    enum Style {
        case primary
        case secondary
        case ghost

        var background: Color {
            switch self {
            case .primary: return .accent
            case .secondary: return .surface
            case .ghost: return .clear
            }
        }

        var foreground: Color {
            switch self {
            case .primary: return .onAccent
            case .secondary: return .textPrimary
            case .ghost: return .textSecondary
            }
        }

        var borderColor: Color {
            switch self {
            case .primary: return .clear
            case .secondary: return .hairline
            case .ghost: return .clear
            }
        }
    }

    let title: String
    var icon: AstraIcon?
    var style: Style = .primary
    var isDisabled: Bool = false
    var action: () -> Void

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.astraBody(13, .semibold))
                    .lineLimit(1)
                if let icon {
                    AstraIconView(icon, size: 11)
                        .frame(width: 20, height: 20)
                        .background(iconBackground)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Spacing.lg)
            .frame(height: 34)
            .background(style.background)
            .foregroundStyle(style.foreground)
            .overlay(RoundedRectangle(cornerRadius: Radius.control).stroke(style.borderColor, lineWidth: 1))
            .clipShape(Capsule())
            .scaleEffect(isPressed && !reduceMotion ? Motion.pressScale : 1)
            .animation(isPressed
                ? .easeOut(duration: Motion.pressDuration)
                : .easeOut(duration: Motion.releaseDuration),
                value: isPressed)
            .opacity(isDisabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        #if os(macOS)
        .onHover { hovering in
            isPressed = hovering
        }
        #endif
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var iconBackground: Color {
        switch style {
        case .primary: return .black.opacity(0.10)
        case .secondary, .ghost: return .hairline
        }
    }
}

/// 30pt icon-only button, hairline circle on hover (native macOS feel).
struct AstraIconButton: View {
    let icon: AstraIcon
    var help: String
    var tint: Color = .textPrimary
    var action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            AstraIconView(icon, size: 13)
                .frame(width: 30, height: 30)
                .foregroundStyle(tint)
                .background(isHovering ? AnyShapeStyle(Color.hairline) : AnyShapeStyle(.clear))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
        #if os(macOS)
        .onHover { isHovering = $0 }
        #endif
    }
}
