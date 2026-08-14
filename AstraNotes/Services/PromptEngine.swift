import Foundation

// MARK: - PromptEngine
// Central prompt orchestrator for the AstraNotes AI pipeline.
// Assembles context from transcription text, subject metadata, and session
// history into well-structured prompt packages.  Manages the token budget
// so that requests stay within the model's context window, and provides
// response-parsing utilities for flashcards and quiz questions.

@Observable
class PromptEngine {

    // MARK: - Token Budget Constants

    /// Maximum input tokens (system + user prompt combined).
    let maxInputTokens = 6000

    /// Maximum output tokens we request from the model.
    let maxOutputTokens = 8192

    /// Tokens reserved for overhead (e.g. model response formatting).
    let reserveTokens = 500

    // MARK: - Prompt Assembly (Note Generation)

    func assembleNoteGenerationPrompt(
        transcription: String,
        subject: Subject?,
        teacher: String? = nil,
        duration: TimeInterval = 0,
        style: String = "detailed",
        outputLanguage: String = "auto"
    ) -> PromptPackage {
        let systemPrompt = NoteGenerationPrompts.systemPrompt(
            subjectName: subject?.name ?? "Unknown",
            level: subject?.level.displayName ?? "HL",
            teacher: teacher ?? "Unknown",
            style: style,
            outputLanguage: outputLanguage
        )

        let userPrompt = NoteGenerationPrompts.userPrompt(
            transcription: transcription,
            subjectName: subject?.name ?? "Unknown",
            level: subject?.level.displayName ?? "HL",
            duration: duration
        )

        return estimateTokenBudget(systemPrompt: systemPrompt, userPrompt: userPrompt)
    }

    // MARK: - Prompt Assembly (Flashcards)

    func assembleFlashcardPrompt(
        noteContent: String,
        subject: Subject?,
        bloomLevel: Int = 2,
        count: Int = 20,
        outputLanguage: String = "auto"
    ) -> PromptPackage {
        let systemPrompt = FlashcardPrompts.systemPrompt(
            subjectName: subject?.name ?? "Unknown",
            bloomLevel: bloomLevel,
            outputLanguage: outputLanguage
        )

        let userPrompt = FlashcardPrompts.userPrompt(
            noteContent: noteContent,
            count: count
        )

        return estimateTokenBudget(systemPrompt: systemPrompt, userPrompt: userPrompt)
    }

    // MARK: - Prompt Assembly (Quiz)

    func assembleQuizPrompt(
        noteContent: String,
        subject: Subject?,
        difficulty: String = "mixed",
        count: Int = 10,
        outputLanguage: String = "auto"
    ) -> PromptPackage {
        let systemPrompt = QuizPrompts.systemPrompt(
            subjectName: subject?.name ?? "Unknown",
            difficulty: difficulty,
            outputLanguage: outputLanguage
        )

        let userPrompt = QuizPrompts.userPrompt(
            noteContent: noteContent,
            count: count,
            difficulty: difficulty
        )

        return estimateTokenBudget(systemPrompt: systemPrompt, userPrompt: userPrompt)
    }

    // MARK: - Prompt Assembly (Study Guide)

    func assembleStudyGuidePrompt(
        noteContents: [String],
        subject: Subject?,
        outputLanguage: String = "auto"
    ) -> PromptPackage {
        let systemPrompt = StudyGuidePrompts.systemPrompt(
            subjectName: subject?.name ?? "Unknown",
            outputLanguage: outputLanguage
        )

        let userPrompt = StudyGuidePrompts.userPrompt(
            noteContents: noteContents,
            subjectName: subject?.name ?? "Unknown"
        )

        return estimateTokenBudget(systemPrompt: systemPrompt, userPrompt: userPrompt)
    }

    // MARK: - Prompt Assembly (TOK)

    func assembleTOKPrompt(
        content: String,
        focus: String = "general",
        outputLanguage: String = "auto"
    ) -> PromptPackage {
        let systemPrompt = TOKPrompts.systemPrompt(outputLanguage: outputLanguage)
        let userPrompt = TOKPrompts.userPrompt(content: content, focus: focus)
        return estimateTokenBudget(systemPrompt: systemPrompt, userPrompt: userPrompt)
    }

    // MARK: - Prompt Assembly (Extended Essay)

    func assembleEEPrompt(
        content: String,
        subject: String,
        stage: String = "planning",
        outputLanguage: String = "auto"
    ) -> PromptPackage {
        let systemPrompt = EEPrompts.systemPrompt(subject: subject, outputLanguage: outputLanguage)
        let userPrompt = EEPrompts.userPrompt(content: content, stage: stage)
        return estimateTokenBudget(systemPrompt: systemPrompt, userPrompt: userPrompt)
    }

    // MARK: - Prompt Assembly (Internal Assessment)

    func assembleIAPrompt(
        content: String,
        subject: String,
        group: Int,
        outputLanguage: String = "auto"
    ) -> PromptPackage {
        let systemPrompt = IAPrompts.systemPrompt(subject: subject, group: group, outputLanguage: outputLanguage)
        let userPrompt = IAPrompts.userPrompt(content: content)
        return estimateTokenBudget(systemPrompt: systemPrompt, userPrompt: userPrompt)
    }

    // MARK: - Prompt Assembly (CAS)

    func assembleCASPrompt(
        activityDescription: String,
        category: String,
        focus: String = "reflection",
        outputLanguage: String = "auto"
    ) -> PromptPackage {
        let systemPrompt = CASPrompts.systemPrompt(outputLanguage: outputLanguage)
        let userPrompt = CASPrompts.userPrompt(
            description: activityDescription,
            category: category,
            focus: focus
        )
        return estimateTokenBudget(systemPrompt: systemPrompt, userPrompt: userPrompt)
    }

    // MARK: - Token Budget Management

    /// Estimates the combined token count of both prompts, calculates how many
    /// output tokens are available, and flags whether the input needs truncation.
    private func estimateTokenBudget(
        systemPrompt: String,
        userPrompt: String
    ) -> PromptPackage {
        let systemTokens = estimateTokenCount(systemPrompt)
        let userTokens = estimateTokenCount(userPrompt)
        let totalInput = systemTokens + userTokens

        let availableForOutput = max(0, maxInputTokens - totalInput - reserveTokens)
        let outputLimit = min(maxOutputTokens, availableForOutput)

        return PromptPackage(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            estimatedInputTokens: totalInput,
            maxOutputTokens: outputLimit,
            needsTruncation: totalInput > maxInputTokens - reserveTokens
        )
    }

    /// Rough token count estimator.
    /// English text: ~4 characters per token.
    /// CJK / other multibyte: ~2 characters per token.
    private func estimateTokenCount(_ text: String) -> Int {
        let englishChars = text.filter { $0.asciiValue != nil }.count
        let nonEnglishChars = text.count - englishChars
        return englishChars / 4 + nonEnglishChars / 2
    }

    /// Truncates `text` so it fits within an approximate token budget.
    /// Appends a notice when truncation occurs.
    func truncateToFit(text: String, maxTokens: Int) -> String {
        let estimatedChars = maxTokens * 3 // Conservative: 3 chars/token
        if text.count <= estimatedChars {
            return text
        }
        return String(text.prefix(estimatedChars))
            + "\n\n[... content truncated to fit token budget ...]"
    }

    // MARK: - Response Parsing (Flashcards)

    /// Parses a markdown-style flashcard response into an array of tuples.
    /// Expected format per card:
    /// ```
    /// ### Card N
    /// **Front:** [question]
    /// **Back:** [answer]
    /// **Hint:** [optional hint]
    /// **Level:** [Bloom's level]
    /// ```
    func parseFlashcardsResponse(
        _ response: String
    ) -> [(front: String, back: String, hint: String?, bloom: String)] {
        var cards: [(front: String, back: String, hint: String?, bloom: String)] = []

        let components = response.components(separatedBy: "### Card")
        for component in components.dropFirst() {
            let lines = component.lines
            var front = ""
            var back = ""
            var hint: String?
            var bloom = ""

            for line in lines {
                let trimmed = line.trimmed
                if trimmed.lowercased().hasPrefix("**front:**") ||
                    trimmed.lowercased().hasPrefix("**question:**") {
                    front = trimmed.replacingOccurrences(
                        of: #"^\*\*(Front|Question):\*\*\s*"#,
                        with: "",
                        options: .regularExpression
                    ).trimmed
                } else if trimmed.lowercased().hasPrefix("**back:**") ||
                    trimmed.lowercased().hasPrefix("**answer:**") {
                    back = trimmed.replacingOccurrences(
                        of: #"^\*\*(Back|Answer):\*\*\s*"#,
                        with: "",
                        options: .regularExpression
                    ).trimmed
                } else if trimmed.lowercased().hasPrefix("**hint:**") ||
                    trimmed.lowercased().hasPrefix("**context:**") {
                    hint = trimmed.replacingOccurrences(
                        of: #"^\*\*(Hint|Context):\*\*\s*"#,
                        with: "",
                        options: .regularExpression
                    ).trimmed
                } else if trimmed.lowercased().hasPrefix("**level:**") {
                    bloom = trimmed.replacingOccurrences(
                        of: #"^\*\*Level:\*\*\s*"#,
                        with: "",
                        options: .regularExpression
                    ).trimmed
                }
            }

            if !front.isEmpty && !back.isEmpty {
                cards.append((front: front, back: back, hint: hint, bloom: bloom))
            }
        }

        return cards
    }

    // MARK: - Response Parsing (Quiz Questions)

    /// Parses a markdown-style quiz response into an array of tuples.
    /// Expected format per question:
    /// ```
    /// ### Question N
    /// **Type:** [multiple_choice / short_answer / essay / data_response]
    /// **Difficulty:** [SL / HL]
    /// **Question:** [question text]
    /// **Options:** (multiple choice only) A) ... B) ... C) ... D) ...
    /// **Answer:** [correct answer]
    /// **Marks:** [integer]
    /// **Explanation:** [optional explanation]
    /// ```
    func parseQuizResponse(
        _ response: String
    ) -> [(
        question: String,
        type: String,
        options: [String],
        answer: String,
        marks: Int,
        explanation: String?
    )] {
        var questions: [(
            question: String,
            type: String,
            options: [String],
            answer: String,
            marks: Int,
            explanation: String?
        )] = []

        let components = response.components(separatedBy: "### Question")
        for component in components.dropFirst() {
            let lines = component.lines
            var questionText = ""
            var type = "short_answer"
            var options: [String] = []
            var answer = ""
            var marks = 1
            var explanation: String?

            for line in lines {
                let trimmed = line.trimmed

                if trimmed.lowercased().hasPrefix("**question:**") {
                    questionText = trimmed.replacingOccurrences(
                        of: #"^\*\*Question:\*\*\s*"#,
                        with: "",
                        options: .regularExpression
                    ).trimmed
                } else if trimmed.lowercased().hasPrefix("**type:**") {
                    type = trimmed.replacingOccurrences(
                        of: #"^\*\*Type:\*\*\s*"#,
                        with: "",
                        options: .regularExpression
                    ).trimmed.lowercased()
                } else if trimmed.lowercased().hasPrefix("**options:**") {
                    let optionsStr = trimmed.replacingOccurrences(
                        of: #"^\*\*Options:\*\*\s*"#,
                        with: "",
                        options: .regularExpression
                    ).trimmed
                    // Split on A) B) C) D) pattern.
                    options = optionsStr.components(separatedBy: #"(?=[A-D]\))"#)
                        .map { $0.trimmed }
                        .filter { !$0.isEmpty }
                } else if trimmed.lowercased().hasPrefix("**answer:**") {
                    answer = trimmed.replacingOccurrences(
                        of: #"^\*\*Answer:\*\*\s*"#,
                        with: "",
                        options: .regularExpression
                    ).trimmed
                } else if trimmed.lowercased().hasPrefix("**marks:**") {
                    let marksStr = trimmed.replacingOccurrences(
                        of: #"^\*\*Marks:\*\*\s*"#,
                        with: "",
                        options: .regularExpression
                    ).trimmed
                    marks = Int(marksStr) ?? 1
                } else if trimmed.lowercased().hasPrefix("**explanation:**") {
                    explanation = trimmed.replacingOccurrences(
                        of: #"^\*\*Explanation:\*\*\s*"#,
                        with: "",
                        options: .regularExpression
                    ).trimmed
                }
            }

            if !questionText.isEmpty {
                questions.append((
                    question: questionText,
                    type: type,
                    options: options,
                    answer: answer,
                    marks: marks,
                    explanation: explanation
                ))
            }
        }

        return questions
    }
}

// MARK: - PromptPackage

/// A self-contained package carrying the assembled system/user prompts along
/// with metadata about token usage that helps callers decide whether to
/// truncate content before sending it to the model.

struct PromptPackage {
    let systemPrompt: String
    let userPrompt: String
    let estimatedInputTokens: Int
    let maxOutputTokens: Int
    let needsTruncation: Bool
}
