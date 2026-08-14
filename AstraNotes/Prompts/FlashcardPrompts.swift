import Foundation

// MARK: - FlashcardPrompts
// Prompt templates for generating IB-style flashcards from study notes.
// Each card targets a specific Bloom's taxonomy level and includes
// optional hint/context and the relevant Bloom's level tag.

enum FlashcardPrompts {

    /// Builds the system prompt for flashcard generation.
    ///
    /// - Parameters:
    ///   - subjectName: The IB subject name.
    ///   - bloomLevel: The Bloom's taxonomy level (1-6).
    /// - Returns: A system prompt string.
    static func systemPrompt(
        subjectName: String,
        bloomLevel: Int,
        outputLanguage: String = "auto"
    ) -> String {
        let bloomName = Self.bloomLevelName(bloomLevel)
        let bloomDescription = Self.bloomLevelDescription(bloomLevel)

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
        你是一位 IB 课程闪卡生成专家。

        从给定的学习笔记中生成闪卡。每张闪卡包含正面（问题）和背面（答案）。

        要求：
        1. 使用布鲁姆分类法第 \(bloomLevel) 级（\(bloomName)：\(bloomDescription)）来设计问题
        2. 每张卡片格式：
           ### Card N
           **Front:** [问题]
           **Back:** [答案]
           **Hint:** [可选的上下文提示]
           **Level:** [布鲁姆级别]
        3. 答案应精确、简洁，适合快速复习
        4. 包含 IB 考试相关内容
        5. HL 专属内容用 [HL] 标注
        6. 生成 15-25 张闪卡
        7. 覆盖笔记中的所有关键概念

        科目：\(subjectName)
        语言要求：\(languageInstruction)。
        """
    }

    /// Builds the user prompt that provides the source note content.
    ///
    /// - Parameters:
    ///   - noteContent: The generated study notes to derive flashcards from.
    ///   - count: The target number of flashcards.
    /// - Returns: A user prompt string.
    static func userPrompt(
        noteContent: String,
        count: Int
    ) -> String {
        """
        从以下学习笔记生成 \(count) 张闪卡：

        \(noteContent)
        """
    }

    // MARK: - Bloom's Taxonomy Helpers

    /// Returns the Chinese name for a Bloom's taxonomy level.
    static func bloomLevelName(_ level: Int) -> String {
        switch level {
        case 1: return "记忆"
        case 2: return "理解"
        case 3: return "应用"
        case 4: return "分析"
        case 5: return "评估"
        case 6: return "创造"
        default: return "理解"
        }
    }

    /// Returns a brief description of the cognitive skill for a given level.
    static func bloomLevelDescription(_ level: Int) -> String {
        switch level {
        case 1: return "Recall facts and basic concepts"
        case 2: return "Explain ideas or concepts"
        case 3: return "Apply knowledge to new situations"
        case 4: return "Draw connections among ideas"
        case 5: return "Justify a stand or decision"
        case 6: return "Produce new or original work"
        default: return "Explain ideas or concepts"
        }
    }
}
