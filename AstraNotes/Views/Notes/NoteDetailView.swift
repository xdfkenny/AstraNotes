import SwiftUI
import SwiftData

// MARK: - NoteDetailView
// Notes library with a list (260pt) and an editor/preview split.
// Editing persists back to the SwiftData model. Preview renders
// Mermaid + LaTeX + HTML via the WebKit MarkdownRenderer.

struct NoteDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @State private var isEditing: Bool = true
    @State private var noteContent: String = ""
    @State private var selectedNote: GeneratedNote?

    @Query(sort: \GeneratedNote.dateGenerated, order: .reverse) private var notes: [GeneratedNote]

    var body: some View {
        HStack(spacing: 0) {
            notesList
                .frame(width: 260)

            Divider()

            if let note = selectedNote {
                editorPreviewSplit(note)
            } else {
                EmptyStateView(
                    icon: .description,
                    title: String(localized: "notes.title"),
                    message: String(localized: "notes.noSelection")
                )
            }
        }
        .background(Color.surfaceBackground)
        .onAppear {
            if selectedNote == nil, let first = notes.first {
                load(first)
            }
        }
    }

    // MARK: - Notes List

    private var notesList: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionHeader(title: String(localized: "notes.title"), icon: .description)
                .padding(.horizontal, Spacing.md)

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(notes) { note in
                        noteRow(note)
                    }
                }
                .padding(.horizontal, Spacing.sm)
            }
        }
        .padding(.vertical, Spacing.sm)
        .background(Color.surfaceBackground)
    }

    private func noteRow(_ note: GeneratedNote) -> some View {
        let isSelected = selectedNote?.id == note.id

        return Button {
            persistCurrentEdit()
            load(note)
        } label: {
            HStack(spacing: Spacing.sm) {
                AstraIconView(note.type.astraIcon, size: 12)
                    .foregroundStyle(isSelected ? Color.accent : Color.textTertiary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 1) {
                    Text(note.title)
                        .font(.astraBody(12, isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.accent : Color.textPrimary)
                        .lineLimit(1)
                    Text(note.displayDate)
                        .font(.astraMono(10))
                        .foregroundStyle(.textTertiary)
                }
                Spacer(minLength: 0)
                if note.isFavorite {
                    AstraIconView(.star, size: 9)
                        .foregroundStyle(Color.semanticWarning)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .frame(height: 36)
            .background(isSelected ? Color.accentContainer : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Radius.control))
            .overlay(alignment: .leading) {
                if isSelected {
                    Rectangle()
                        .fill(Color.accent)
                        .frame(width: 3, height: 18)
                        .clipShape(RoundedRectangle(cornerRadius: 1.5))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Editor / Preview Split

    private func editorPreviewSplit(_ note: GeneratedNote) -> some View {
        VStack(spacing: 0) {
            toolbar(note)

            Divider()

            if isEditing {
                TextEditor(text: $noteContent)
                    .font(.system(size: 13, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(Color.surfaceBackground)
                    .padding(Spacing.lg)
            } else {
                ScrollView {
                    MarkdownPreview(markdown: noteContent, isDark: colorScheme == .dark)
                        .frame(minHeight: 600)
                }
            }
        }
    }

    private func toolbar(_ note: GeneratedNote) -> some View {
        HStack(spacing: Spacing.sm) {
            // Favorite toggle
            AstraIconButton(
                icon: .star,
                help: String(localized: "notes.favorite"),
                tint: note.isFavorite ? .semanticWarning : .textTertiary
            ) {
                note.isFavorite.toggle()
            }

            Spacer()

            // Edit / Preview toggle
            HStack(spacing: 2) {
                TagChip(
                    text: String(localized: "notes.edit"),
                    isSelected: isEditing
                ) {
                    persistCurrentEdit()
                    withAnimation(Motion.stateChange) { isEditing = true }
                }
                TagChip(
                    text: String(localized: "notes.preview"),
                    isSelected: !isEditing
                ) {
                    persistCurrentEdit()
                    withAnimation(Motion.stateChange) { isEditing = false }
                }
            }

            Spacer()

            AstraIconButton(icon: .share, help: String(localized: "common.share")) {}
        }
        .padding(.horizontal, Spacing.lg)
        .frame(height: 44)
        .background(Color.surface)
    }

    // MARK: - Actions

    private func load(_ note: GeneratedNote) {
        selectedNote = note
        noteContent = note.content
        isEditing = true
    }

    /// Writes the editor buffer back to the model when switching notes
    /// or leaving edit mode.
    private func persistCurrentEdit() {
        guard let note = selectedNote else { return }
        if note.content != noteContent {
            note.content = noteContent
            note.lastEdited = Date()
            note.wordCount = noteContent.wordCount
        }
    }
}
