import SwiftUI
import SwiftData

// MARK: - NoteDetailView
// A split-pane note viewer and editor. The left panel lists all generated
// notes; the right panel provides an edit/preview toggle with a toolbar
// of pill-styled CryoButtons. In preview mode the markdown content is
// rendered in a WebKit-backed MarkdownPreview view with Cryo CSS.

struct NoteDetailView: View {
    @Environment(\.themeManager) private var tm
    @State private var isEditing: Bool = true
    @State private var noteContent: String = "# My Note\n\nStart writing..."
    @State private var selectedNote: GeneratedNote?
    @Query private var notes: [GeneratedNote]

    var body: some View {
        HStack(spacing: 0) {
            // Notes list
            notesList

            Divider()
                .background(CryoColors.border(tm))

            // Editor / Preview
            editorPreviewSplit
        }
        .background(CryoColors.background(tm))
    }

    // MARK: - Notes List Panel

    private var notesList: some View {
        VStack(spacing: 0) {
            Text(String(localized: "notes.title"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(CryoColors.foreground(tm))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)

            Divider()
                .background(CryoColors.border(tm))

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(notes) { note in
                        noteRow(note)
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 260)
        .background(CryoColors.backgroundWarm(tm))
    }

    private func noteRow(_ note: GeneratedNote) -> some View {
        let isSelected = selectedNote?.id == note.id

        return Button {
            selectedNote = note
            noteContent = note.content
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(CryoColors.foreground(tm))
                    .lineLimit(1)
                HStack {
                    Text(note.displayDate)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                    Spacer()
                    if note.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#FBBF24"))
                    }
                }
            }
            .padding(10)
            .background(isSelected ? CryoColors.accent(tm).opacity(0.1) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Editor / Preview Panel

    private var editorPreviewSplit: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()
                .background(CryoColors.border(tm))

            if isEditing {
                // Markdown text editor
                TextEditor(text: $noteContent)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(CryoColors.foreground(tm))
                    .scrollContentBackground(.hidden)
                    .padding(16)
                    .background(CryoColors.backgroundWarm(tm))
            } else {
                // Rendered markdown preview
                MarkdownPreview(markdown: noteContent, isDark: tm.isDark)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 8) {
            // Edit / Preview toggle pill group
            HStack(spacing: 0) {
                CryoButton(String(localized: "notes.edit"), style: .primary, action: { isEditing = true })
                CryoButton(String(localized: "notes.preview"), style: .secondary, action: { isEditing = false })
            }

            Spacer()

            CryoButton(icon: "paperplane", style: .icon()) {}
            CryoButton(icon: "arrow.down.doc", style: .icon()) {}
            CryoButton(icon: "square.and.arrow.up", style: .icon()) {}
        }
        .padding(12)
        .background(CryoColors.backgroundWarm(tm))
    }
}

// MARK: - MarkdownPreview
// A placeholder for the WebKit-backed markdown renderer. In production
// this would wrap a WKWebView with custom Cryo-themed CSS to render
// markdown content. For now it displays the raw markdown text as a
// fallback until the WebKit component is integrated.

struct MarkdownPreview: View {
    let markdown: String
    let isDark: Bool

    var body: some View {
        ScrollView {
            Text(markdown)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(isDark ? Color(hex: "#E8F4FC") : Color(hex: "#2C3E50"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
        }
        .background(isDark ? Color(hex: "#0F1729") : Color(hex: "#F0F7FF"))
    }
}
