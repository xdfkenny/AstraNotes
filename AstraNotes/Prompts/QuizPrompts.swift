import Foundation

// MARK: - QuizPrompts
// Prompt templates for generating IB-style quiz questions from study notes.
// Supports multiple question types aligned with Paper 1 (MCQ) and Paper 2
// (short answer / essay) formats, including marks allocation and explanations.

enum QuizPrompts {

    /// Builds the system prompt for quiz generation.
    ///
    /// - Parameters:
    ///   - subjectName: The IB subject name.
    ///   - difficulty: The difficulty level ("SL", "HL", or "mixed").
    /// - Returns: A system prompt string.
    static func systemPrompt(
        subjectName: String,
        difficulty: String,
        outputLanguage: String = "auto"
    ) -> String {
        let difficultyDescription: String
        switch difficulty.lowercased() {
        case "sl":
            difficultyDescription = "SL 标准 (Standard Level only)"
        case "hl":
            difficultyDescription = "HL 拓展 (Higher Level, includes extension topics)"
        case "mixed":
            difficultyDescription = "Mixed 混合 (combines SL and HL questions)"
        default:
            difficultyDescription = "Mixed 混合 (combines SL and HL questions)"
        }

        let languageInstruction: String
        switch outputLanguage {
        case "auto":
            languageInstruction = "与讲座语言一致"
        default:
            let languageName: String
            switch outputLanguage {
            case "en": languageName = "English"
            case "es": languageName = "Spanish (Español)"
            case "zh": languageName = "Chinese (中文)"
            case "fr": languageName = "French (Français)"
            case "de": languageName = "German (Deutsch)"
            case "ja": languageName = "Japanese (日本語)"
            case "ko": languageName = "Korean (한국어)"
            case "pt": languageName = "Portuguese (Português)"
            case "ar": languageName = "Arabic (العربية)"
            case "hi": languageName = "Hindi (हिन्दी)"
            case "ru": languageName = "Russian (Русский)"
            case "it": languageName = "Italian (Italiano)"
            default: languageName = outputLanguage
            }
            languageInstruction = "所有内容必须使用 \(languageName) 输出"
        }

        return """
        你是一位 IB 考试题生成专家。

        从给定的学习笔记中生成测验题目。

        要求：
        1. 题目格式：
           ### Question N
           **Type:** [multiple_choice / short_answer / essay / data_response]
           **Difficulty:** [SL / HL]
           **Question:** [题目文本]
           **Options:** (仅选择题) A) ... B) ... C) ... D) ...
           **Answer:** [正确答案]
           **Marks:** [分数]
           **Explanation:** [解析]
        2. 题型分布：
           - Paper 1 风格选择题（4 选项）
           - Paper 2 风格简答题
           - 论述题（含评分方案）
        3. 难度：\(difficultyDescription)
        4. 包含 IB 考试标记方式
        5. 每题标注分数 [X marks]

        科目：\(subjectName)
        语言要求：\(languageInstruction)。
        """
    }

    /// Builds the user prompt that provides the source note content.
    ///
    /// - Parameters:
    ///   - noteContent: The generated study notes to derive questions from.
    ///   - count: The target number of questions.
    ///   - difficulty: The difficulty level string.
    /// - Returns: A user prompt string.
    static func userPrompt(
        noteContent: String,
        count: Int,
        difficulty: String
    ) -> String {
        """
        从以下学习笔记生成 \(count) 道测验题，难度级别：\(difficulty)

        \(noteContent)
        """
    }
}
