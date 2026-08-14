// TOKPlannerView.swift — AstraNotes
// Theory of Knowledge exhibition and essay planner.
// Features knowledge question cards with gradient borders,
// WOK/AOK pill tag selectors, real-world situation analysis,
// and related notes linking, with the Astra design system.

import SwiftUI
import SwiftData

// MARK: - TOK Planner View

struct TOKPlannerView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var selectedNote: TOKNote?
    @State private var knowledgeQuestion: String = ""
    @State private var selectedWOKs: Set<String> = []
    @State private var selectedAOKs: Set<String> = []
    @State private var realWorldSituation: String = ""
    @State private var analysisText: String = ""
    @State private var showNewNoteAlert: Bool = false
    @State private var searchText: String = ""
    @State private var isEditing: Bool = false

    // MARK: - Queries

    @Query(sort: \TOKNote.dateCreated, order: .reverse) private var tokNotes: [TOKNote]

    // MARK: - Filtered Notes

    private var filteredNotes: [TOKNote] {
        if searchText.isEmpty {
            return tokNotes
        }
        return tokNotes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.knowledgeQuestion.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection
                knowledgeQuestionSection
                wokAOKSection
                realWorldSection
                analysisSection
                relatedNotesSection
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceBackground)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                AstraIconView(.psychology, size: 22)
                    .foregroundStyle(Color.accent)
                Text(String(localized: "tok.title"))
                    .font(TypeScale.title)
                    .foregroundColor(Color.textPrimary)
            }

            Text(String(localized: "tok.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)

            HStack {
                Spacer()

                // Note count
                Text("^[\(tokNotes.count) note](inflect: true)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color.textSecondary)

                Button {
                    createNewNote()
                } label: {
                    HStack(spacing: 6) {
                        AstraIconView(.add, size: 12)
                        Text(String(localized: "tok.newNote"))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accent)
                    .clipShape(Capsule())
                    .shadow(color: Color.accent.opacity(0.15), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Knowledge Question Section

    private var knowledgeQuestionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "tok.knowledgeQuestion"), icon: .help)

            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $knowledgeQuestion)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 60)
                    .padding(12)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.hairline, lineWidth: 1)
                    )

                if knowledgeQuestion.isEmpty {
                    HStack(spacing: 6) {
                        AstraIconView(.lightbulb, size: 11)
                            .foregroundColor(Color.accent)
                        Text(String(localized: "tok.kqPlaceholder"))
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }
        }
        .padding(20)
        .astraCardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    Color.accent.opacity(0.6),
                    lineWidth: 2
                )
        )
    }

    // MARK: - WOK / AOK Selector

    private var wokAOKSection: some View {
        HStack(alignment: .top, spacing: 20) {
            // Ways of Knowing
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel(String(localized: "tok.waysOfKnowing"), icon: .visibility)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(TOKNote.allWOKs, id: \.self) { wok in
                        let isSelected = selectedWOKs.contains(wok)
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                if isSelected {
                                    selectedWOKs.remove(wok)
                                } else {
                                    selectedWOKs.insert(wok)
                                }
                            }
                        } label: {
                            Text(wok)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? .white : Color.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    isSelected
                                        ? Color.accent
                                        : Color.surface
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            isSelected
                                                ? Color.accent
                                                : Color.hairline,
                                            lineWidth: 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .astraCardStyle()

            // Areas of Knowledge
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel(String(localized: "tok.areasOfKnowledge"), icon: .globe)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(TOKNote.allAOKs, id: \.self) { aok in
                        let isSelected = selectedAOKs.contains(aok)
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                if isSelected {
                                    selectedAOKs.remove(aok)
                                } else {
                                    selectedAOKs.insert(aok)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(isSelected ? Color.accent : Color.hairline)
                                    .frame(width: 6, height: 6)
                                Text(aok)
                                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                    .foregroundColor(isSelected ? .white : Color.textPrimary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                isSelected
                                    ? Color.accent
                                    : Color.surface
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isSelected
                                            ? Color.accent
                                            : Color.hairline,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .astraCardStyle()
        }
    }

    // MARK: - Real World Situation

    private var realWorldSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "tok.realWorldSituation"), icon: .`public`)

            TextEditor(text: $realWorldSituation)
                .font(.system(size: 14))
                .foregroundColor(Color.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(12)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.hairline, lineWidth: 1)
                )

            if !realWorldSituation.isEmpty {
                HStack(spacing: 6) {
                    AstraIconView(.link, size: 11)
                        .foregroundColor(Color.accent)
                    Text(String(localized: "tok.rwsHint"))
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }
            }
        }
        .padding(20)
        .astraCardStyle()
    }

    // MARK: - Analysis Section

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(String(localized: "tok.analysis"), icon: .editNote)

            HStack(spacing: 16) {
                // Selected WOK summary
                if !selectedWOKs.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "tok.selectedWOKs"))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.accent)
                            .tracking(0.06)
                        HStack(spacing: 6) {
                            ForEach(Array(selectedWOKs).sorted(), id: \.self) { wok in
                                Text(wok)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentContainer)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                if !selectedAOKs.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "tok.selectedAOKs"))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.accent)
                            .tracking(0.06)
                        HStack(spacing: 6) {
                            ForEach(Array(selectedAOKs).sorted(), id: \.self) { aok in
                                Text(aok)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.accent.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentContainer)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            TextEditor(text: $analysisText)
                .font(.system(size: 14))
                .foregroundColor(Color.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .padding(12)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.hairline, lineWidth: 1)
                )

            // Save button
            HStack {
                Spacer()
                Button {
                    saveCurrentNote()
                } label: {
                    HStack(spacing: 6) {
                        AstraIconView(.checkCircle, size: 13)
                        Text(String(localized: "common.save"))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accent)
                    .clipShape(Capsule())
                    .shadow(color: Color.accent.opacity(0.15), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(knowledgeQuestion.isEmpty && analysisText.isEmpty)
                .opacity(knowledgeQuestion.isEmpty && analysisText.isEmpty ? 0.4 : 1.0)
            }
        }
        .padding(20)
        .astraCardStyle()
    }

    // MARK: - Related Notes

    private var relatedNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel(String(localized: "tok.notes"), icon: .description)

                Spacer()

                // Search field
                HStack(spacing: 6) {
                    AstraIconView(.search, size: 12)
                        .foregroundColor(Color.textSecondary)
                    TextField(String(localized: "tok.searchNotes"), text: $searchText)
                        .font(.system(size: 13))
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.hairline, lineWidth: 1)
                )
                .frame(width: 200)
            }

            if filteredNotes.isEmpty {
                VStack(spacing: 12) {
                    AstraIconView(.psychology, size: 32)
                        .foregroundColor(Color.textSecondary.opacity(0.3))
                    Text(String(localized: "tok.noNotes"))
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
                    Text(String(localized: "tok.noNotesHint"))
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(filteredNotes) { note in
                        tokNoteCard(note)
                    }
                }
            }
        }
    }

    // MARK: - TOK Note Card

    private func tokNoteCard(_ note: TOKNote) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                        .lineLimit(1)

                    Text(note.knowledgeQuestion)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.accent)
                        .lineLimit(2)
                }

                Spacer()

                // Date badge
                Text(note.dateCreated.shortDateString)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentContainer)
                    .clipShape(Capsule())
            }

            // WOK pills
            if !note.waysOfKnowing.isEmpty {
                HStack(spacing: 6) {
                    ForEach(note.waysOfKnowing, id: \.self) { wok in
                        Text(wok)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.accentContainer)
                            .clipShape(Capsule())
                    }
                }
            }

            // AOK pills
            if !note.areasOfKnowledge.isEmpty {
                HStack(spacing: 6) {
                    ForEach(note.areasOfKnowledge, id: \.self) { aok in
                        Text(aok)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.accent.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.accentContainer)
                            .clipShape(Capsule())
                    }
                }
            }

            // Tags
            if !note.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(note.tags.prefix(4), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 10))
                            .foregroundColor(Color.textSecondary)
                    }
                    if note.tags.count > 4 {
                        Text("+\(note.tags.count - 4)")
                            .font(.system(size: 10))
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }
        }
        .padding(16)
        .astraCardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    selectedNote?.id == note.id
                        ? Color.accent.opacity(0.6)
                        : Color.hairline,
                    lineWidth: selectedNote?.id == note.id ? 2 : 1
                )
        )
        .onTapGesture {
            selectedNote = note
            loadNote(note)
        }
    }

    // MARK: - Helper Views

    private func sectionLabel(_ title: String, icon: AstraIcon) -> some View {
        HStack(spacing: 6) {
            AstraIconView(icon, size: 12)
                .foregroundColor(Color.accent)
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color.textPrimary)
                .tracking(0.02)
        }
    }

    // MARK: - Actions

    private func createNewNote() {
        let note = TOKNote(
            title: String(format: String(localized: "tok.reflectionTitle"), tokNotes.count + 1),
            knowledgeQuestion: knowledgeQuestion,
            waysOfKnowing: Array(selectedWOKs),
            areasOfKnowledge: Array(selectedAOKs),
            realWorldSituation: realWorldSituation.isEmpty ? nil : realWorldSituation
        )
        modelContext.insert(note)
        selectedNote = note
    }

    private func saveCurrentNote() {
        guard var note = selectedNote else {
            createNewNote()
            return
        }
        note.knowledgeQuestion = knowledgeQuestion
        note.waysOfKnowing = Array(selectedWOKs)
        note.areasOfKnowledge = Array(selectedAOKs)
        note.realWorldSituation = realWorldSituation.isEmpty ? nil : realWorldSituation
        note.content = analysisText
        note.lastEdited = Date()
    }

    private func loadNote(_ note: TOKNote) {
        knowledgeQuestion = note.knowledgeQuestion
        selectedWOKs = Set(note.waysOfKnowing)
        selectedAOKs = Set(note.areasOfKnowledge)
        realWorldSituation = note.realWorldSituation ?? ""
        analysisText = note.content
        isEditing = true
    }
}

// MARK: - Preview

#Preview {
    TOKPlannerView()
        
        .modelContainer(for: TOKNote.self, inMemory: true)
}
