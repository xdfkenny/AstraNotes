import Foundation

// MARK: - TOKPrompts
// Prompt templates for IB Theory of Knowledge (TOK) analysis.
// Covers knowledge questions, exhibition planning, essay analysis,
// and general WOK/AOK exploration.

enum TOKPrompts {

    /// The eight Ways of Knowing (WOK) in the current TOK curriculum.
    static let waysOfKnowing: [String] = [
        "语言 (Language)",
        "感知 (Sense Perception)",
        "情感 (Emotion)",
        "理性 (Reason)",
        "想象 (Imagination)",
        "信仰 (Faith)",
        "直觉 (Intuition)",
        "记忆 (Memory)"
    ]

    /// The eight Areas of Knowledge (AOK) in the current TOK curriculum.
    static let areasOfKnowledge: [String] = [
        "自然科学 (Natural Sciences)",
        "人文科学 (Human Sciences)",
        "历史 (History)",
        "艺术 (The Arts)",
        "伦理 (Ethics)",
        "宗教知识体系 (Religious Knowledge Systems)",
        "本土知识体系 (Indigenous Knowledge Systems)",
        "数学 (Mathematics)"
    ]

    /// Builds the system prompt for TOK analysis.
    ///
    /// - Returns: A system prompt string.
    static func systemPrompt(outputLanguage: String = "auto") -> String {
        let wokList = waysOfKnowing.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        let aokList = areasOfKnowledge.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

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
        你是一位 IB 知识理论（Theory of Knowledge）专家。

        你帮助分析知识问题，探索认知方式（WOK）和知识领域（AOK）的关系。

        认知方式（WOK）：
        \(wokList)

        知识领域（AOK）：
        \(aokList)

        输出格式：Markdown，含知识问题、WOK/AOK 分析、真实世界情境链接。
        语言要求：\(languageInstruction)。
        """
    }

    /// Builds the user prompt with a specific TOK focus.
    ///
    /// - Parameters:
    ///   - content: The source material or essay question to analyse.
    ///   - focus: One of "knowledge_question", "exhibition", "essay", or "general".
    /// - Returns: A user prompt string.
    static func userPrompt(
        content: String,
        focus: String
    ) -> String {
        let focusInstruction: String
        switch focus {
        case "knowledge_question":
            focusInstruction = """
            生成知识问题（Knowledge Question），并分析相关的 WOK 和 AOK。

            要求：
            1. 从给定内容中提取 2-3 个真实世界情境（Real-World Situations）
            2. 为每个情境生成一个知识问题
            3. 分析该问题涉及的认知方式（WOK）和知识领域（AOK）
            4. 提供不同视角的论证
            """
        case "exhibition":
            focusInstruction = """
            为 TOK 展览生成分析，包括：
            1. 选择一个核心主题 / 提示（Prompt）
            2. 推荐 3 个展示对象（Exhibition Objects）
            3. 分析每个对象与知识问题的关联
            4. 撰写展览说明文件（Exhibition Commentary）
            """
        case "essay":
            focusInstruction = """
            分析这个 TOK 论文题目，包括：
            1. 识别核心知识问题
            2. 构建论证框架（Thesis + Antithesis + Synthesis）
            3. 整合相关的 WOK 和 AOK
            4. 引用真实世界范例
            5. 评估论证的局限性
            """
        case "general":
            fallthrough
        default:
            focusInstruction = """
            从给定内容中提取 TOK 相关的知识问题和分析。
            识别涉及的认知方式（WOK）和知识领域（AOK），
            并提供多视角的论证。
            """
        }

        return """
        \(focusInstruction)

        内容：
        \(content)
        """
    }
}
