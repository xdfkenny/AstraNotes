import Foundation

// MARK: - StudyGuidePrompts
// Prompt templates for synthesising a comprehensive IB study guide from
// multiple lecture notes.  The output includes formula sheets, terminology
// glossaries, Mermaid concept maps, IB exam tips, and a syllabus-aligned
// revision checklist.

enum StudyGuidePrompts {

    /// Builds the system prompt for study guide generation.
    ///
    /// - Parameter subjectName: The IB subject name.
    /// - Returns: A system prompt string.
    static func systemPrompt(
        subjectName: String,
        outputLanguage: String = "auto"
    ) -> String {
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
        你是一位 IB 课程学习指南生成专家。

        从多堂讲座笔记中生成综合学习指南。

        要求：
        1. 结构：
           - 主题概述与目标
           - 核心概念总结
           - 公式表（使用 LaTeX）
           - 关键术语表
           - 概念图（Mermaid）
           - 复习清单（与 IB 教学大纲对齐）
           - 常见错误
           - IB 考试技巧
        2. 公式使用 LaTeX：行内 $...$，块级 $$...$$
        3. 图表使用 Mermaid 语法
        4. 表格用于对比和总结
        5. 复习清单标注重要程度（⭐ 必修 / ⭐⭐ 推荐 / ⭐⭐⭐ 拓展）

        科目：\(subjectName)
        语言要求：\(languageInstruction)。
        """
    }

    /// Builds the user prompt that combines multiple lecture notes.
    ///
    /// - Parameters:
    ///   - noteContents: An array of individual lecture note strings.
    ///   - subjectName: The IB subject name.
    /// - Returns: A user prompt string.
    static func userPrompt(
        noteContents: [String],
        subjectName: String
    ) -> String {
        let combinedNotes = noteContents.enumerated()
            .map { "\n--- 讲座 \($0.offset + 1) ---\n\($0.element)" }
            .joined()

        return """
        从以下多堂讲座笔记生成综合学习指南：

        科目：\(subjectName)
        讲座数量：\(noteContents.count)

        \(combinedNotes)
        """
    }
}
