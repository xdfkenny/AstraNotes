// QuizView.swift — AstraNotes
// Quiz engine with Soft Cryo ice crystal design aesthetic.
// Features: quiz configuration (subject, difficulty, type, question count),
// timer (pill-shaped, JetBrains Mono), progress bar (6px, cornerRadius full),
// pill-shaped answer options, results dashboard with hexagonal icons.

import SwiftUI
import SwiftData

// MARK: - Quiz View

struct QuizView: View {

    // MARK: - Environment

    @Environment(\.themeManager) private var tm
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var quizState: QuizState = .setup
    @State private var selectedSubject: String = String(localized: "quiz.allSubjects")
    @State private var selectedDifficulty: QuestionDifficulty = .mixed
    @State private var selectedType: QuestionType? = nil // nil = all types
    @State private var questionCount: Int = 10
    @State private var isTimed: Bool = true
    @State private var timeLimit: Int = 30 // seconds per question

    // Active quiz state
    @State private var quizQuestions: [QuizQuestion] = []
    @State private var currentIndex: Int = 0
    @State private var selectedAnswer: String = ""
    @State private var shortAnswerInput: String = ""
    @State private var hasAnswered: Bool = false
    @State private var isCorrect: Bool = false
    @State private var timeRemaining: Int = 30
    @State private var timer: Timer?
    @State private var score: Int = 0
    @State private var answers: [QuizAnswer] = []
    @State private var quizStartTime: Date = .now

    // MARK: - Queries

    @Query private var allQuestions: [QuizQuestion]

    // MARK: - Computed Properties

    private var subjects: [String] {
        let unique = Array(Set(allQuestions.compactMap { $0.subjectName })).sorted()
        return [String(localized: "quiz.allSubjects")] + unique
    }

    private var currentQuestion: QuizQuestion? {
        guard currentIndex < quizQuestions.count else { return nil }
        return quizQuestions[currentIndex]
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            CryoColors.background(tm)
                .ignoresSafeArea()

            switch quizState {
            case .setup:
                setupView
            case .active:
                activeQuizView
            case .results:
                resultsView
            }
        }
    }

    // MARK: - Setup View

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection
                configurationSection
                availableQuestionsInfo
                startButton
            }
            .padding(32)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("❄️")
                    .font(.system(size: 24))
                Text(String(localized: "quiz.title"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(CryoColors.foreground(tm))
            }

            Text(String(localized: "quiz.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(CryoColors.foregroundMuted(tm))
        }
    }

    private var configurationSection: some View {
        HStack(spacing: 20) {
            // Left column: filters
            VStack(alignment: .leading, spacing: 20) {
                // Subject selector
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "quiz.subject"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(CryoColors.accentDark(tm))
                        .tracking(0.08)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(subjects, id: \.self) { subject in
                                Button {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        selectedSubject = subject
                                    }
                                } label: {
                                    Text(subject)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(selectedSubject == subject ? .white : CryoColors.foreground(tm))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(
                                            selectedSubject == subject
                                                ? LinearGradient(
                                                    colors: [CryoColors.accent(tm), CryoColors.accentDark(tm)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                                : CryoColors.backgroundWarm(tm)
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(
                                                selectedSubject == subject ? CryoColors.accent(tm) : CryoColors.border(tm),
                                                lineWidth: 1
                                            )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Difficulty selector
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "quiz.difficulty"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(CryoColors.accentDark(tm))
                        .tracking(0.08)

                    HStack(spacing: 8) {
                        ForEach(QuestionDifficulty.allCases, id: \.self) { difficulty in
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    selectedDifficulty = difficulty
                                }
                            } label: {
                                Text(difficulty.rawValue)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(selectedDifficulty == difficulty ? .white : CryoColors.foreground(tm))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedDifficulty == difficulty
                                            ? LinearGradient(
                                                colors: [CryoColors.accent(tm), CryoColors.accentDark(tm)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            : CryoColors.backgroundWarm(tm)
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(
                                            selectedDifficulty == difficulty ? CryoColors.accent(tm) : CryoColors.border(tm),
                                            lineWidth: 1
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Question type selector
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "quiz.questionType"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(CryoColors.accentDark(tm))
                        .tracking(0.08)

                    HStack(spacing: 8) {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                selectedType = nil
                            }
                        } label: {
                            Text(String(localized: "quiz.allTypes"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selectedType == nil ? .white : CryoColors.foreground(tm))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selectedType == nil
                                        ? CryoColors.accent(tm)
                                        : CryoColors.backgroundWarm(tm)
                                )
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(selectedType == nil ? CryoColors.accent(tm) : CryoColors.border(tm), lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        ForEach(QuestionType.allCases, id: \.self) { type in
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    selectedType = type
                                }
                            } label: {
                                Text(type.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(selectedType == type ? .white : CryoColors.foreground(tm))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedType == type
                                            ? CryoColors.accent(tm)
                                            : CryoColors.backgroundWarm(tm)
                                    )
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(selectedType == type ? CryoColors.accent(tm) : CryoColors.border(tm), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Question count & timer row
                HStack(spacing: 16) {
                    // Question count
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "quiz.questions"))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(CryoColors.accentDark(tm))
                            .tracking(0.08)

                        HStack(spacing: 12) {
                            ForEach([5, 10, 15, 20], id: \.self) { count in
                                Button {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        questionCount = count
                                    }
                                } label: {
                                    Text("\(count)")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundColor(questionCount == count ? .white : CryoColors.foreground(tm))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 7)
                                        .background(
                                            questionCount == count
                                                ? LinearGradient(
                                                    colors: [CryoColors.accent(tm), CryoColors.accentDark(tm)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                                : CryoColors.backgroundWarm(tm)
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(
                                                questionCount == count ? CryoColors.accent(tm) : CryoColors.border(tm),
                                                lineWidth: 1
                                            )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Timer toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "quiz.timer"))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(CryoColors.accentDark(tm))
                            .tracking(0.08)

                        HStack(spacing: 10) {
                            Toggle(String(localized: "quiz.timed"), isOn: $isTimed)
                                .toggleStyle(.switch)
                                .tint(CryoColors.accent(tm))

                            if isTimed {
                                Picker("", selection: $timeLimit) {
                                    Text("15s").tag(15)
                                    Text("30s").tag(30)
                                    Text("45s").tag(45)
                                    Text("60s").tag(60)
                                }
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .frame(width: 160)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .cryoCardStyle(tm)

            // Right column: overview stats
            VStack(spacing: 16) {
                statCard(
                    icon: "questionmark.circle",
                    label: String(localized: "quiz.totalQuestions"),
                    value: "\(allQuestions.count)",
                    color: CryoColors.accent(tm)
                )
                statCard(
                    icon: "target",
                    label: String(localized: "quiz.avgAccuracy"),
                    value: allQuestions.isEmpty ? "--" : String(format: "%.0f%%", averageAccuracy * 100),
                    color: averageAccuracy >= 0.7 ? CryoColors.success(tm) : CryoColors.warning(tm)
                )
                statCard(
                    icon: "clock",
                    label: String(localized: "quiz.timeLimit"),
                    value: isTimed ? String(localized: "quiz.timePerQuestion \(timeLimit)") : String(localized: "quiz.untimed"),
                    color: CryoColors.accentDark(tm)
                )
                statCard(
                    icon: "square.stack",
                    label: String(localized: "quiz.quizSize"),
                    value: "\(questionCount) questions",
                    color: CryoColors.roseIce(tm)
                )
            }
            .frame(maxWidth: 260)
        }
    }

    private func statCard(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(CryoColors.foregroundMuted(tm))
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(CryoColors.foreground(tm))
            }

            Spacer()
        }
        .padding(16)
        .cryoCardStyle(tm, cornerRadius: 12)
    }

    private var availableQuestionsInfo: some View {
        let available = filteredQuestionsForSetup.count
        let hasEnough = available >= questionCount

        return HStack(spacing: 10) {
            Image(systemName: hasEnough ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(hasEnough ? CryoColors.success(tm) : CryoColors.warning(tm))

            Text(hasEnough
                 ? String(localized: "quiz.questionsAvailable \(available)")
                 : String(localized: "quiz.onlyQuestionsAvailable \(available)")
            )
            .font(.system(size: 13))
            .foregroundColor(CryoColors.foregroundMuted(tm))
        }
        .padding(16)
        .background(hasEnough ? CryoColors.success(tm).opacity(0.06) : CryoColors.warning(tm).opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var startButton: some View {
        Button {
            startQuiz()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 18))
                Text(String(localized: "quiz.startQuiz"))
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [CryoColors.accent(tm), CryoColors.accentDark(tm)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: CryoColors.shadowGlow(tm), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(filteredQuestionsForSetup.isEmpty)
        .opacity(filteredQuestionsForSetup.isEmpty ? 0.5 : 1.0)
    }

    // MARK: - Active Quiz View

    private var activeQuizView: some View {
        VStack(spacing: 24) {
            // Top bar: progress + timer
            VStack(spacing: 12) {
                HStack {
                    Text(String(localized: "quiz.questionOf \(currentIndex + 1) \(quizQuestions.count)"))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(CryoColors.accentDark(tm))
                        .tracking(0.1)

                    Spacer()

                    if let question = currentQuestion {
                        HStack(spacing: 6) {
                            Text(question.difficulty.rawValue)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(
                                    question.difficulty == .hl
                                        ? CryoColors.warning(tm)
                                        : CryoColors.accent(tm)
                                )
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    (question.difficulty == .hl
                                        ? CryoColors.warning(tm)
                                        : CryoColors.accent(tm)
                                    ).opacity(0.1)
                                )
                                .clipShape(Capsule())

                            Text(question.type.displayName)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(CryoColors.foregroundMuted(tm))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(CryoColors.frost(tm))
                                .clipShape(Capsule())
                        }
                    }
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
                            .frame(width: geo.size.width * progressFraction, height: 6)
                            .animation(.easeOut(duration: 0.3), value: currentIndex)
                    }
                }
                .frame(height: 6)
            }

            // Timer pill
            HStack {
                Spacer()
                if isTimed {
                    HStack(spacing: 8) {
                        Image(systemName: timeRemaining <= 10 ? "timer" : "clock")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(timeRemaining <= 10 ? CryoColors.error(tm) : CryoColors.accent(tm))

                        Text(String(format: "%02d", timeRemaining))
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(timeRemaining <= 10 ? CryoColors.error(tm) : CryoColors.foreground(tm))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        timeRemaining <= 10
                            ? CryoColors.error(tm).opacity(0.08)
                            : CryoColors.backgroundWarm(tm)
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            timeRemaining <= 10 ? CryoColors.error(tm).opacity(0.3) : CryoColors.border(tm),
                            lineWidth: 1
                        )
                    )
                    .animation(.easeInOut(duration: 0.3), value: timeRemaining)
                }
                Spacer()
            }

            // Question card
            if let question = currentQuestion {
                questionCard(question)
                answerSection(question)
            }
        }
        .padding(32)
    }

    private var progressFraction: Double {
        guard !quizQuestions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(quizQuestions.count)
    }

    // MARK: - Question Card

    private func questionCard(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question header
            HStack {
                if let subject = question.subjectName {
                    Text(subject)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(CryoColors.accent(tm))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(CryoColors.accentGlow(tm))
                        .clipShape(Capsule())
                }

                if !question.topic.isBlank {
                    Text(question.topic)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                }

                Spacer()

                Text(question.type.paperStyle)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CryoColors.accentDark(tm))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(CryoColors.accentDark(tm).opacity(0.08))
                    .clipShape(Capsule())
            }

            Divider()
                .background(CryoColors.border(tm))

            // Question content
            Text(question.content)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(CryoColors.foreground(tm))
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Marks display
            HStack {
                Text(String(localized: "quiz.marks \(question.maxMarks)"))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CryoColors.accentDark(tm))
                Spacer()
            }
        }
        .padding(24)
        .cryoCardStyle(tm)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(CryoColors.crystalBorderGradient(tm), lineWidth: 1.5)
        )
    }

    // MARK: - Answer Section

    @ViewBuilder
    private func answerSection(_ question: QuizQuestion) -> some View {
        switch question.type {
        case .multipleChoice:
            multipleChoiceAnswers(question)
        case .shortAnswer:
            shortAnswerInput(question)
        case .essay:
            essayInput(question)
        case .dataResponse, .extendedResponse:
            extendedAnswerInput(question)
        }
    }

    // MARK: - Multiple Choice Answers

    private func multipleChoiceAnswers(_ question: QuizQuestion) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                Button {
                    selectAnswer(option, for: question)
                } label: {
                    HStack(spacing: 14) {
                        // Option letter in hexagon
                        ZStack {
                            HexagonShape()
                                .fill(optionColor(for: option, question: question))
                                .frame(width: 36, height: 36)

                            Text(optionLetter(index))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }

                        Text(option)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(CryoColors.foreground(tm))
                            .multilineTextAlignment(.leading)

                        Spacer()

                        if hasAnswered {
                            if option == question.correctAnswer {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(CryoColors.success(tm))
                            } else if option == selectedAnswer && selectedAnswer != question.correctAnswer {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(CryoColors.error(tm))
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        hasAnswered
                            ? answerBackground(for: option, question: question)
                            : CryoColors.backgroundWarm(tm)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                hasAnswered
                                    ? answerBorderColor(for: option, question: question)
                                    : CryoColors.border(tm),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(hasAnswered)
            }

            // Explanation
            if hasAnswered, let explanation = question.explanation {
                explanationCard(explanation)
            }

            // Next button
            if hasAnswered {
                Button {
                    nextQuestion()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: currentIndex + 1 < quizQuestions.count ? "arrow.right" : "flag.checkered")
                        Text(currentIndex + 1 < quizQuestions.count ? String(localized: "quiz.nextQuestion") : String(localized: "quiz.seeResults"))
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
                    .shadow(color: CryoColors.shadowGlow(tm), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Short Answer Input

    private func shortAnswerInput(_ question: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            TextField(String(localized: "quiz.typeAnswer"), text: $shortAnswerInput, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundColor(CryoColors.foreground(tm))
                .padding(16)
                .background(CryoColors.frost(tm))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CryoColors.border(tm), lineWidth: 1)
                )
                .lineLimit(3...6)
                .disabled(hasAnswered)

            HStack {
                Spacer()

                if !hasAnswered {
                    Button {
                        submitShortAnswer(for: question)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                            Text(String(localized: "quiz.submitAnswer"))
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 9)
                        .background(
                            LinearGradient(
                                colors: [CryoColors.accent(tm), CryoColors.accentDark(tm)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(shortAnswerInput.isBlank)
                    .opacity(shortAnswerInput.isBlank ? 0.5 : 1.0)
                }

                if hasAnswered {
                    VStack(spacing: 8) {
                        if let explanation = question.explanation {
                            explanationCard(explanation)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(isCorrect ? CryoColors.success(tm) : CryoColors.error(tm))

                            Text(isCorrect
                                 ? String(localized: "quiz.correctExclamation")
                                 : String(localized: "quiz.notQuite \(question.correctAnswer)"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(CryoColors.foreground(tm))
                        }
                        .padding(16)
                        .cryoCardStyle(tm, cornerRadius: 12)

                        Button {
                            nextQuestion()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: currentIndex + 1 < quizQuestions.count ? "arrow.right" : "flag.checkered")
                                Text(currentIndex + 1 < quizQuestions.count ? String(localized: "quiz.nextQuestion") : String(localized: "quiz.seeResults"))
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
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Essay Input

    private func essayInput(_ question: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            TextEditor(text: $shortAnswerInput)
                .font(.system(size: 15))
                .foregroundColor(CryoColors.foreground(tm))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 160)
                .padding(16)
                .background(CryoColors.frost(tm))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CryoColors.border(tm), lineWidth: 1)
                )
                .disabled(hasAnswered)

            // Marking scheme reference
            if let markingScheme = question.markingScheme, !markingScheme.isBlank {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.clipboard")
                            .font(.system(size: 11))
                            .foregroundColor(CryoColors.accentDark(tm))
                        Text(String(localized: "quiz.markingScheme"))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(CryoColors.accentDark(tm))
                            .tracking(0.08)
                    }

                    Text(markingScheme)
                        .font(.system(size: 13))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                        .lineSpacing(4)
                }
                .padding(16)
                .background(CryoColors.accentGlow(tm))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack {
                Spacer()

                if !hasAnswered {
                    Button {
                        submitEssay(for: question)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                            Text(String(localized: "quiz.selfAssess"))
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 9)
                        .background(
                            LinearGradient(
                                colors: [CryoColors.accent(tm), CryoColors.accentDark(tm)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(shortAnswerInput.isBlank)
                }

                if hasAnswered {
                    Button {
                        nextQuestion()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: currentIndex + 1 < quizQuestions.count ? "arrow.right" : "flag.checkered")
                            Text(currentIndex + 1 < quizQuestions.count ? String(localized: "quiz.nextQuestion") : String(localized: "quiz.seeResults"))
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
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Extended Answer Input (Data Response / Extended Response)

    private func extendedAnswerInput(_ question: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            TextEditor(text: $shortAnswerInput)
                .font(.system(size: 15))
                .foregroundColor(CryoColors.foreground(tm))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 200)
                .padding(16)
                .background(CryoColors.frost(tm))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CryoColors.border(tm), lineWidth: 1)
                )
                .disabled(hasAnswered)

            if let markingScheme = question.markingScheme, !markingScheme.isBlank {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.clipboard")
                            .font(.system(size: 11))
                            .foregroundColor(CryoColors.accentDark(tm))
                        Text(String(localized: "quiz.markingScheme"))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(CryoColors.accentDark(tm))
                            .tracking(0.08)
                    }

                    Text(markingScheme)
                        .font(.system(size: 13))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                        .lineSpacing(4)
                }
                .padding(16)
                .background(CryoColors.accentGlow(tm))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack {
                Text(String(localized: "quiz.selfAssessHint"))
                    .font(.system(size: 12))
                    .foregroundColor(CryoColors.foregroundMuted(tm).opacity(0.6))

                Spacer()

                if !hasAnswered {
                    Button {
                        submitEssay(for: question)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                            Text(String(localized: "quiz.submit"))
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 9)
                        .background(
                            LinearGradient(
                                colors: [CryoColors.accent(tm), CryoColors.accentDark(tm)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(shortAnswerInput.isBlank)
                }

                if hasAnswered {
                    Button {
                        nextQuestion()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: currentIndex + 1 < quizQuestions.count ? "arrow.right" : "flag.checkered")
                            Text(currentIndex + 1 < quizQuestions.count ? String(localized: "quiz.next") : String(localized: "quiz.results"))
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 9)
                        .background(
                            LinearGradient(
                                colors: [CryoColors.accent(tm), CryoColors.accentDark(tm)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Results View

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Results header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(CryoColors.accentGlow(tm))
                            .frame(width: 80, height: 80)

                        Image(systemName: score == quizQuestions.count ? "trophy.fill" : "chart.bar")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(CryoColors.accent(tm))
                    }

                    Text(String(localized: "quiz.quizComplete"))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(CryoColors.foreground(tm))

                    Text(String(localized: "quiz.scoredOutOf \(score) \(quizQuestions.count)"))
                        .font(.system(size: 16))
                        .foregroundColor(CryoColors.foregroundMuted(tm))
                }

                // Score dashboard with hexagonal icons
                HStack(spacing: 16) {
                    // Correct
                    VStack(spacing: 10) {
                        ZStack {
                            HexagonShape()
                                .fill(CryoColors.success(tm).opacity(0.15))
                                .frame(width: 56, height: 56)

                            Text("\(score)")
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundColor(CryoColors.success(tm))
                        }

                        Text(String(localized: "quiz.correctAnswer"))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(CryoColors.foregroundMuted(tm))
                            .tracking(0.06)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .cryoCardStyle(tm)

                    // Incorrect
                    VStack(spacing: 10) {
                        ZStack {
                            HexagonShape()
                                .fill(CryoColors.error(tm).opacity(0.15))
                                .frame(width: 56, height: 56)

                            Text("\(quizQuestions.count - score)")
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundColor(CryoColors.error(tm))
                        }

                        Text(String(localized: "quiz.incorrectAnswer"))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(CryoColors.foregroundMuted(tm))
                            .tracking(0.06)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .cryoCardStyle(tm)

                    // Percentage
                    VStack(spacing: 10) {
                        ZStack {
                            HexagonShape()
                                .fill(
                                    scorePercentage >= 0.7
                                        ? CryoColors.success(tm).opacity(0.15)
                                        : CryoColors.warning(tm).opacity(0.15)
                                )
                                .frame(width: 56, height: 56)

                            Text(String(format: "%.0f%%", scorePercentage * 100))
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundColor(
                                    scorePercentage >= 0.7
                                        ? CryoColors.success(tm)
                                        : CryoColors.warning(tm)
                                )
                        }

                        Text(String(localized: "quiz.score"))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(CryoColors.foregroundMuted(tm))
                            .tracking(0.06)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .cryoCardStyle(tm)

                    // Time
                    VStack(spacing: 10) {
                        ZStack {
                            HexagonShape()
                                .fill(CryoColors.accent(tm).opacity(0.15))
                                .frame(width: 56, height: 56)

                            Image(systemName: "clock")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(CryoColors.accent(tm))
                        }

                        Text(quizElapsedTime)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(CryoColors.foregroundMuted(tm))
                            .tracking(0.06)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .cryoCardStyle(tm)
                }

                // Question-by-question review
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "quiz.questionReview"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(CryoColors.accentDark(tm))
                        .tracking(0.08)

                    ForEach(Array(answers.enumerated()), id: \.offset) { index, answer in
                        answerReviewRow(index: index, answer: answer)
                    }
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        quizState = .setup
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape")
                            Text(String(localized: "quiz.newQuiz"))
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(CryoColors.accentDark(tm))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(CryoColors.backgroundWarm(tm))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(CryoColors.border(tm), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        retryQuiz()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text(String(localized: "quiz.retryQuestions"))
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
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(32)
        }
    }

    private var scorePercentage: Double {
        guard !quizQuestions.isEmpty else { return 0 }
        return Double(score) / Double(quizQuestions.count)
    }

    private var quizElapsedTime: String {
        let interval = quizStartTime.distance(to: .now)
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        }
        return String(format: "%ds", seconds)
    }

    // MARK: - Answer Review Row

    private func answerReviewRow(index: Int, answer: QuizAnswer) -> some View {
        HStack(spacing: 14) {
            ZStack {
                HexagonShape()
                    .fill(answer.isCorrect ? CryoColors.success(tm).opacity(0.15) : CryoColors.error(tm).opacity(0.15))
                    .frame(width: 32, height: 32)

                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(answer.isCorrect ? CryoColors.success(tm) : CryoColors.error(tm))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(answer.questionContent)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(CryoColors.foreground(tm))
                    .lineLimit(1)

                Text(String(localized: "quiz.yourAnswer \(answer.userAnswer)"))
                    .font(.system(size: 11))
                    .foregroundColor(answer.userAnswer.isBlank ? CryoColors.foregroundMuted(tm) : CryoColors.foregroundMuted(tm).opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: answer.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(answer.isCorrect ? CryoColors.success(tm) : CryoColors.error(tm))
        }
        .padding(14)
        .cryoCardStyle(tm, cornerRadius: 12)
    }

    // MARK: - Explanation Card

    private func explanationCard(_ explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(CryoColors.accent(tm))
                Text(String(localized: "quiz.explanation"))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(CryoColors.accentDark(tm))
                    .tracking(0.08)
            }

            Text(explanation)
                .font(.system(size: 14))
                .foregroundColor(CryoColors.foreground(tm))
                .lineSpacing(4)
        }
        .padding(16)
        .background(CryoColors.accentGlow(tm))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helper: Option Colors

    private func optionColor(for option: String, question: QuizQuestion) -> Color {
        guard hasAnswered else {
            return option == selectedAnswer ? CryoColors.accent(tm) : CryoColors.accentDark(tm)
        }
        if option == question.correctAnswer { return CryoColors.success(tm) }
        if option == selectedAnswer { return CryoColors.error(tm) }
        return CryoColors.foregroundMuted(tm).opacity(0.3)
    }

    private func optionLetter(_ index: Int) -> String {
        String(UnicodeScalar("A".unicodeScalarValue! + index)!)
    }

    private func answerBackground(for option: String, question: QuizQuestion) -> Color {
        if option == question.correctAnswer { return CryoColors.success(tm).opacity(0.08) }
        if option == selectedAnswer && selectedAnswer != question.correctAnswer { return CryoColors.error(tm).opacity(0.08) }
        return CryoColors.backgroundWarm(tm)
    }

    private func answerBorderColor(for option: String, question: QuizQuestion) -> Color {
        if option == question.correctAnswer { return CryoColors.success(tm).opacity(0.4) }
        if option == selectedAnswer && selectedAnswer != question.correctAnswer { return CryoColors.error(tm).opacity(0.4) }
        return CryoColors.border(tm)
    }

    // MARK: - Computed Helpers

    private var filteredQuestionsForSetup: [QuizQuestion] {
        var result = allQuestions

        if selectedSubject != String(localized: "quiz.allSubjects") {
            result = result.filter { $0.subjectName == selectedSubject }
        }

        if selectedDifficulty != .mixed {
            result = result.filter { $0.difficulty == selectedDifficulty }
        }

        if let type = selectedType {
            result = result.filter { $0.type == type }
        }

        return result
    }

    private var averageAccuracy: Double {
        let reviewed = allQuestions.filter { $0.timesAnswered > 0 }
        guard !reviewed.isEmpty else { return 0 }
        return Double(reviewed.reduce(0) { $0 + $1.correctCount }) / Double(reviewed.reduce(0) { $0 + $1.timesAnswered })
    }

    // MARK: - Actions

    private func startQuiz() {
        var pool = filteredQuestionsForSetup.shuffled()
        if pool.count > questionCount {
            pool = Array(pool.prefix(questionCount))
        }
        quizQuestions = pool
        currentIndex = 0
        score = 0
        answers = []
        selectedAnswer = ""
        shortAnswerInput = ""
        hasAnswered = false
        quizStartTime = .now
        timeRemaining = timeLimit
        quizState = .active

        if isTimed {
            startTimer()
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    // Time's up — auto-submit if not answered
                    stopTimer()
                    if !hasAnswered {
                        timeUp()
                    }
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func timeUp() {
        guard let question = currentQuestion else { return }
        hasAnswered = true
        isCorrect = false
        selectedAnswer = ""

        question.timesAnswered += 1

        answers.append(QuizAnswer(
            questionContent: question.content,
            userAnswer: String(localized: "quiz.timeExpired"),
            correctAnswer: question.correctAnswer,
            isCorrect: false
        ))
    }

    private func selectAnswer(_ answer: String, for question: QuizQuestion) {
        selectedAnswer = answer
        hasAnswered = true
        isCorrect = answer == question.correctAnswer

        if isCorrect { score += 1 }

        question.timesAnswered += 1
        if isCorrect { question.timesCorrect += 1 }

        answers.append(QuizAnswer(
            questionContent: question.content,
            userAnswer: answer,
            correctAnswer: question.correctAnswer,
            isCorrect: isCorrect
        ))

        stopTimer()
    }

    private func submitShortAnswer(for question: QuizQuestion) {
        hasAnswered = true
        isCorrect = shortAnswerInput.trimmed.lowercased() == question.correctAnswer.lowercased()

        if isCorrect { score += 1 }

        question.timesAnswered += 1
        if isCorrect { question.timesCorrect += 1 }

        answers.append(QuizAnswer(
            questionContent: question.content,
            userAnswer: shortAnswerInput.trimmed,
            correctAnswer: question.correctAnswer,
            isCorrect: isCorrect
        ))

        stopTimer()
    }

    private func submitEssay(for question: QuizQuestion) {
        // For essay/extended, self-assessed as correct
        hasAnswered = true
        isCorrect = true
        score += 1

        question.timesAnswered += 1
        question.timesCorrect += 1

        answers.append(QuizAnswer(
            questionContent: question.content,
            userAnswer: shortAnswerInput.trimmed,
            correctAnswer: question.correctAnswer,
            isCorrect: true
        ))

        stopTimer()
    }

    private func nextQuestion() {
        if currentIndex + 1 < quizQuestions.count {
            currentIndex += 1
            selectedAnswer = ""
            shortAnswerInput = ""
            hasAnswered = false
            timeRemaining = timeLimit

            if isTimed {
                startTimer()
            }
        } else {
            stopTimer()
            quizState = .results
        }
    }

    private func retryQuiz() {
        startQuiz()
    }
}

// MARK: - Quiz State

enum QuizState {
    case setup
    case active
    case results
}

// MARK: - Quiz Answer Record

struct QuizAnswer: Identifiable {
    var id = UUID()
    var questionContent: String
    var userAnswer: String
    var correctAnswer: String
    var isCorrect: Bool
}

// MARK: - Preview

#Preview {
    QuizView()
        .environment(ThemeManager())
        .modelContainer(for: QuizQuestion.self, inMemory: true)
}
