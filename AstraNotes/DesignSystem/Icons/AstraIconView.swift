//
//  AstraIconView.swift
//  AstraNotes
//
//  Renders a Google Material Symbols glyph from the bundled variable font.
//  The font is registered at app launch (FontRegistrar); glyphs are plain
//  text, so foregroundStyle tints and any size work naturally.
//

import SwiftUI
import CoreText

// MARK: - Font Registration

enum FontRegistrar {
    /// Registers the bundled Material Symbols font so `Font.custom` resolves.
    /// Call once from `AstraNotesApp.init()`.
    static func register() {
        guard let url = Bundle.main.url(forResource: "MaterialSymbolsOutlined", withExtension: "ttf") else {
            assertionFailure("MaterialSymbolsOutlined.ttf missing from bundle")
            return
        }
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        if let error {
            assertionFailure("Font registration failed: \(error.takeRetainedValue())")
        }
    }
}

// MARK: - Icon View

/// A Material Symbols glyph at a given size, tintable via foregroundStyle.
struct AstraIconView: View {
    let icon: AstraIcon
    var size: CGFloat = 14

    /// Unlabeled first argument keeps call sites terse: `AstraIconView(.mic, size: 13)`.
    init(_ icon: AstraIcon, size: CGFloat = 14) {
        self.icon = icon
        self.size = size
    }

    var body: some View {
        Text(icon.rawValue)
            .font(.custom("Material Symbols Outlined", size: size))
            .lineLimit(1)
            .fixedSize()
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("Astra Icon Set") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: Spacing.md) {
            ForEach(AstraIcon.allCases) { icon in
                VStack(spacing: 4) {
                    AstraIconView(icon, size: 22)
                        .foregroundStyle(Color.accent)
                    Text(icon.rawValue)
                        .font(.astraMono(8))
                        .foregroundStyle(.textTertiary)
                        .lineLimit(1)
                }
                .padding(8)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card)
                        .stroke(Color.hairline, lineWidth: 1)
                )
            }
        }
        .padding(Spacing.lg)
    }
    .background(Color.surfaceBackground)
    .frame(width: 640, height: 480)
}
