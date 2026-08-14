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
// Deliberately simple: a complex ForEach grid trips the Swift type checker.

#Preview("Astra Icon Set") {
    HStack(spacing: 12) {
        AstraIconView(.mic, size: 22)
        AstraIconView(.school, size: 22)
        AstraIconView(.psychology, size: 22)
        AstraIconView(.science, size: 22)
        AstraIconView(.autoAwesome, size: 22)
    }
    .padding(24)
    .background(Color.surfaceBackground)
    .frame(width: 320, height: 120)
}
