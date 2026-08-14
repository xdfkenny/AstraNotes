// FlashcardReviewView.swift — AstraNotes
// Spaced repetition flashcard review with Soft Cryo ice crystal design.
// Features: 3D flip animation, SM-2 quality rating buttons (Again/Hard/Good/Easy),
// progress bar, card counter, deck/subject filtering, and session statistics.

import SwiftUI
import SwiftData

// MARK: - Flashcard Review View

struct FlashcardReviewView: View {

    // MARK: - Environment

    @Environment(\.themeManager) private var tm
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var selectedDeck: String = String(localized: "flashcards.allDecks")
    @State private var selectedSubject: String = String(localized: "flashcards.allSubjects")
    @State private var isShowingAnswer: Bool = false
    @State private var flipAngle: Double = 0
    @State private var currentCardIndex: Int = 0
    @State private var sessionCorrect: Int = 0
    @State private var sessionTotal: Int = 0
    @State private var showSessionComplete: Bool = false
    @State private var isStudyMode: Bool = false
    @State private var searchText: String = ""

    // MARK: - Queries

    @Query private var allCards: [Flashcard]

    // MARK: - Computed Properties

    private var decks: [String] {
        Array(Set(allCards.map { $0.deckName })).sorted()
    }

    private var subjects: [String] {
        let unique = Array(Set(allCards.compactMap { $0.subjectName })).sorted()
        return unique
    }

    private var filteredCards: [Flashcard] {
        var result = allCards

        if selectedDeck != String(localized: "flashcards.allDecks") {
            result = result.filter { $0.deckName == selectedDeck }
        }

        if selectedSubject != String(localized: "flashcards.allSubjects") {
            result = result.filter { $0.subjectName == selectedSubject }
        }

        if !searchText.isBlank {
            let query = searchText.lowercased()
            result = result.filter {
                $0.frontContent.lowercased().contains(query) ||
                $0.backContent.lowercased().contains(query) ||
                $0.deckName.lowercased().contains(query) ||
                $0.tags.contains { $0.lowercased().contains(query) }
            }
        }

        if isStudyMode {
            return result.sorted { $0.nextReviewDate < $1.nextReviewDate }
        } else {
            return result.filter { $0.isDue }.sorted { $0.nextReviewDate < $1.nextReviewDate }
        }
    }

    private var dueCount: Int {
        allCards.filter { $0.isDue }.count
    }

    private var totalCount: Int {
        allCards.count
    }

    private var overallAccuracy: Double {
        let reviewed = allCards.filter { $0.reviewCount > 0 }
        guard !reviewed.isEmpty else { return 0 }
        return Double(reviewed.reduce(0) { $0 + $1.correctCount }) / Double(reviewed.reduce(0) { $0 + $1.reviewCount })
    }

    private var currentCard: Flashcard? {
        guard currentCardIndex >= 0, currentCardIndex < filteredCards.count else { return nil }
        return filteredCards[currentCardIndex]
    }

    private var sessionProgress: Double {
        guard !filteredCards.isEmpty else { return 0 }
        return Double(sessionTotal) / Double(filteredCards.count)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection
                filterSection

                if filteredCards.isEmpty {
                    emptyState
                } else {
                    progressSection
                    cardSection
                    ratingButtonsSection
                    sessionStatsSection
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CryoColors.background(tm))
        .sheet(isPresented: $showSessionComplete) {
            sessionCompleteSheet
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("❄️")
                        .font(.system(size: 24))
                    Text(String(localized: "flashcards.title"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(CryoColors.foreground(tm))
                }

                Text(String(localized: "flashcards.subtitle"))
                    .font(.system(size: 14))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
            }

            Spacer()

            // Global stats pills
            HStack(spacing: 10) {
                statPill(
                    label: String(localized: "flashcards.due"),
                    value: "\(dueCount)",
                    color: CryoColors.accent(tm)
                )
                statPill(
                    label: String(localized: "flashcards.total"),
                    value: "\(totalCount)",
                    color: CryoColors.foreground(tm)
                )
                statPill(
                    label: String(localized: "flashcards.accuracy"),
                    value: String(format: "%.0f%%", overallAccuracy * 100),
                    color: overallAccuracy >= 0.7 ? CryoColors.success(tm) : CryoColors.warning(tm)
                )
            }
        }
    }

    private func statPill(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(CryoColors.foregroundMuted(tm))
                .textCase(.uppercase)
                .tracking(0.06)

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(CryoColors.backgroundWarm(tm))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(CryoColors.border(tm), lineWidth: 1))
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        HStack(spacing: 12) {
            // Deck picker
            Menu {
                Button(String(localized: "flashcards.allDecks")) {
                    withAnimation { selectedDeck = String(localized: "flashcards.allDecks"); resetSession() }
                }
                Divider()
                ForEach(decks, id: \.self) { deck in
                    Button(deck) {
                        withAnimation { selectedDeck = deck; resetSession() }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.stack.3d.up")
                    Text(selectedDeck)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(CryoColors.foreground(tm))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(CryoColors.backgroundWarm(tm))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(CryoColors.border(tm), lineWidth: 1))
            }
#if os(macOS)
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
#endif

            // Subject picker
            Menu {
                Button(String(localized: "flashcards.allSubjects")) {
                    withAnimation { selectedSubject = String(localized: "flashcards.allSubjects"); resetSession() }
                }
                Divider()
                ForEach(subjects, id: \.self) { subject in
                    Button(subject) {
                        withAnimation { selectedSubject = subject; resetSession() }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "book")
                    Text(selectedSubject)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(CryoColors.foreground(tm))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(CryoColors.backgroundWarm(tm))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(CryoColors.border(tm), lineWidth: 1))
            }
#if os(macOS)
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
#endif

            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
                    TextField(String(localized: "flashcards.searchCards"), text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(CryoColors.foreground(tm))
                    .frame(width: 160)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(CryoColors.backgroundWarm(tm))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(CryoColors.border(tm), lineWidth: 1))

            Spacer()

            // Study mode toggle (shows all cards, not just due)
            Button {
                withAnimation { isStudyMode.toggle(); resetSession() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isStudyMode ? "eye" : "clock")
                    Text(isStudyMode ? String(localized: "flashcards.studyMode") : String(localized: "flashcards.reviewDue"))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isStudyMode ? CryoColors.accent(tm) : CryoColors.foregroundMuted(tm))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isStudyMode ? CryoColors.accentGlow(tm) : CryoColors.backgroundWarm(tm))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isStudyMode ? CryoColors.accent(tm) : CryoColors.border(tm), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text(String(localized: "flashcards.cardOf \(currentCardIndex + 1) \(filteredCards.count)"))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(CryoColors.accentDark(tm))
                    .tracking(0.08)

                Spacer()

                Text(String(localized: "flashcards.sessionReviewed \(sessionTotal)"))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
                    .tracking(0.06)
            }

            // Progress bar (6px, cornerRadius full)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CryoColors.frost(tm))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [CryoColors.accent(tm), CryoColors.accentDark(tm)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * sessionProgress, height: 6)
                        .animation(.easeOut(duration: 0.3), value: sessionTotal)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Card Section

    private var cardSection: some View {
        ZStack {
            if let card = currentCard {
                VStack(spacing: 24) {
                    // Card container with 3D flip
                    ZStack {
                        // Front of card
                        cardFace(
                            isFront: true,
                            content: card.frontContent,
                            card: card
                        )
                        .rotation3DEffect(
                            .degrees(flipAngle),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.4
                        )
                        .opacity(flipAngle < 90 ? 1 : 0)

                        // Back of card
                        cardFace(
                            isFront: false,
                            content: card.backContent,
                            card: card
                        )
                        .rotation3DEffect(
                            .degrees(flipAngle + 180),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.4
                        )
                        .opacity(flipAngle >= 90 ? 1 : 0)
                    }
                    .frame(height: 300)

                    // Show Answer / Flip button
                    if !isShowingAnswer {
                        Button {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                                flipAngle += 180
                                isShowingAnswer = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text(String(localized: "flashcards.showAnswer"))
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [CryoColors.accent(tm), CryoColors.accentDark(tm)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: CryoColors.shadowGlow(tm), radius: 10, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Card Face

    private func cardFace(isFront: Bool, content: String, card: Flashcard) -> some View {
        VStack(spacing: 0) {
            // Card header
            HStack {
                Text(isFront ? String(localized: "flashcards.question") : String(localized: "flashcards.answer"))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CryoColors.accentDark(tm))
                    .tracking(0.1)

                Spacer()

                // Bloom level badge
                HStack(spacing: 4) {
                    Image(systemName: "brain")
                        .font(.system(size: 10))
                    Text(card.bloomLevel.rawValue)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
                .foregroundColor(Color(hex: card.bloomLevel.color))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(hex: card.bloomLevel.color).opacity(0.1))
                .clipShape(Capsule())

                // Deck badge
                Text(card.deckName)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(CryoColors.frost(tm))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()
                .background(CryoColors.border(tm))
                .padding(.horizontal, 20)

            // Content
            ScrollView {
                Text(content)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(CryoColors.foreground(tm))
                    .lineSpacing(6)
                    .multilineTextAlignment(.center)
                    .padding(24)
                    .frame(maxWidth: .infinity)
            }

            // Context hint (front side only)
            if isFront, let hint = card.contextHint, !hint.isBlank {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 11))
                    Text(hint)
                        .font(.system(size: 12))
                }
                .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.7))
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            // Tags (back side only)
            if !isFront && !card.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(card.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(CryoColors.accent(tm))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(CryoColors.accentGlow(tm))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            // SM-2 info (back side only)
            if !isFront {
                HStack(spacing: 16) {
                    Label {
                        Text(String(format: "%.1f", card.easeFactor))
                    } icon: {
                        Image(systemName: "gauge")
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm))

                    Label {
                        Text(String(format: "%.0f days", card.interval))
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm))

                    Label {
                        Text(String(format: "%.0f%%", card.accuracy * 100))
                    } icon: {
                        Image(systemName: "chart.bar")
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CryoColors.backgroundWarm(tm))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(CryoColors.crystalBorderGradient(tm), lineWidth: 1.5)
        )
        .shadow(color: CryoColors.shadowGlow(tm), radius: 12, x: 0, y: 4)
    }

    // MARK: - Rating Buttons Section

    private var ratingButtonsSection: some View {
        Group {
            if isShowingAnswer {
                VStack(spacing: 12) {
                    Text(String(localized: "flashcards.howWell"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(CryoColors.foregroundMuted(tm))

                    HStack(spacing: 12) {
                        // Again (quality: 0)
                        ratingButton(
                            label: String(localized: "flashcards.again"),
                            icon: "xmark.circle",
                            quality: 0,
                            color: CryoColors.error(tm),
                            description: String(localized: "flashcards.againDescription")
                        )

                        // Hard (quality: 2)
                        ratingButton(
                            label: String(localized: "flashcards.hard"),
                            icon: "arrow.uturn.backward",
                            quality: 2,
                            color: CryoColors.warning(tm),
                            description: String(localized: "flashcards.hardDescription")
                        )

                        // Good (quality: 3)
                        ratingButton(
                            label: String(localized: "flashcards.good"),
                            icon: "checkmark.circle",
                            quality: 3,
                            color: CryoColors.success(tm),
                            description: String(localized: "flashcards.goodDescription")
                        )

                        // Easy (quality: 5)
                        ratingButton(
                            label: String(localized: "flashcards.easy"),
                            icon: "bolt.circle",
                            quality: 5,
                            color: CryoColors.accent(tm),
                            description: String(localized: "flashcards.easyDescription")
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private func ratingButton(
        label: String,
        icon: String,
        quality: Int,
        color: Color,
        description: String
    ) -> some View {
        Button {
            rateCard(quality: quality)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)

                Text(label)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(CryoColors.foreground(tm))

                Text(description)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
                    .tracking(0.04)
            }
            .frame(width: 110, height: 80)
            .background(CryoColors.backgroundWarm(tm))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.3), lineWidth: 1.5)
            )
            .shadow(color: color.opacity(0.1), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Session Stats Section

    private var sessionStatsSection: some View {
        HStack(spacing: 16) {
            // Session accuracy
            VStack(spacing: 8) {
                Text(sessionTotal > 0 ? String(format: "%.0f%%", Double(sessionCorrect) / Double(sessionTotal) * 100) : "--")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(
                        sessionTotal > 0 && Double(sessionCorrect) / Double(sessionTotal) >= 0.7
                            ? CryoColors.success(tm)
                            : CryoColors.accent(tm)
                    )

                Text(String(localized: "flashcards.sessionAccuracy"))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
                    .tracking(0.06)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .cryoCardStyle(tm)

            // Correct count
            VStack(spacing: 8) {
                Text("\(sessionCorrect)")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(CryoColors.success(tm))

                Text(String(localized: "flashcards.correct"))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
                    .tracking(0.06)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .cryoCardStyle(tm)

            // Remaining
            VStack(spacing: 8) {
                Text("\(max(0, filteredCards.count - currentCardIndex - 1))")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(CryoColors.accent(tm))

                Text(String(localized: "flashcards.remaining"))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
                    .tracking(0.06)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .cryoCardStyle(tm)

            // Skip button
            Button {
                advanceToNext()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "forward")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(CryoColors.foregroundMuted(tm))

                    Text(String(localized: "flashcards.skip"))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                        .tracking(0.06)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .cryoCardStyle(tm)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 48))
                .foregroundColor(CryoColors.frost(tm))

            Text(isStudyMode ? String(localized: "flashcards.noCardsMatch") : String(localized: "flashcards.noCardsDue"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(CryoColors.foregroundMuted(tm))

            if !isStudyMode {
                Text(String(localized: "flashcards.noCardsDueHint"))
                    .font(.system(size: 14))
                    .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Session Complete Sheet

    private var sessionCompleteSheet: some View {
        VStack(spacing: 24) {
            // Crystal decoration
            ZStack {
                Circle()
                    .fill(CryoColors.accentGlow(tm))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(CryoColors.accent(tm))
            }

            Text(String(localized: "flashcards.sessionComplete"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(CryoColors.foreground(tm))

            // Stats grid
            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("\(sessionTotal)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(CryoColors.accent(tm))
                    Text(String(localized: "flashcards.reviewed"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .cryoCardStyle(tm)

                VStack(spacing: 8) {
                    Text("\(sessionCorrect)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(CryoColors.success(tm))
                    Text(String(localized: "flashcards.correct"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .cryoCardStyle(tm)

                VStack(spacing: 8) {
                    Text(sessionTotal > 0 ? String(format: "%.0f%%", Double(sessionCorrect) / Double(sessionTotal) * 100) : "--")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(
                            sessionTotal > 0 && Double(sessionCorrect) / Double(sessionTotal) >= 0.7
                                ? CryoColors.success(tm) : CryoColors.warning(tm)
                        )
                    Text(String(localized: "flashcards.accuracy"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .cryoCardStyle(tm)
            }

            HStack(spacing: 12) {
                Button(String(localized: "common.close")) {
                    showSessionComplete = false
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(CryoColors.foregroundMuted(tm))
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(CryoColors.backgroundWarm(tm))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(CryoColors.border(tm), lineWidth: 1))
                .buttonStyle(.plain)

                Button(String(localized: "flashcards.newSession")) {
                    resetSession()
                    showSessionComplete = false
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [CryoColors.accent(tm), CryoColors.accentDark(tm)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .buttonStyle(.plain)
            }
        }
        .padding(32)
        .frame(width: 480)
        .background(CryoColors.backgroundWarm(tm))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(CryoColors.crystalBorderGradient(tm), lineWidth: 1.5)
        )
        .shadow(color: CryoColors.shadowGlow(tm), radius: 16, x: 0, y: 4)
    }

    // MARK: - Actions

    private func rateCard(quality: Int) {
        guard let card = currentCard else { return }

        let result = card.updateAfterReview(quality: quality)
        card.easeFactor = result.easeFactor
        card.interval = result.interval
        card.repetitions = result.repetitions
        card.nextReviewDate = result.nextReviewDate
        card.lastReviewDate = .now
        card.reviewCount += 1

        if quality >= 3 {
            card.correctCount += 1
            sessionCorrect += 1
        }

        sessionTotal += 1
        advanceToNext()
    }

    private func advanceToNext() {
        if currentCardIndex + 1 >= filteredCards.count {
            // Session complete
            showSessionComplete = true
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                currentCardIndex += 1
                flipAngle = 0
                isShowingAnswer = false
            }
        }
    }

    private func resetSession() {
        currentCardIndex = 0
        sessionCorrect = 0
        sessionTotal = 0
        flipAngle = 0
        isShowingAnswer = false
    }
}

// MARK: - Preview

#Preview {
    FlashcardReviewView()
        .environment(ThemeManager())
        .modelContainer(for: Flashcard.self, inMemory: true)
}
