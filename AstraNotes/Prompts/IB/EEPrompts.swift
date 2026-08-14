import Foundation

// MARK: - EEPrompts
// Prompt templates for IB Extended Essay (EE) guidance.
// Supports all stages of the EE process: planning, researching, drafting,
// and reflecting (RPPF).  References the A-F assessment criteria.

enum EEPrompts {

    /// Builds the system prompt for Extended Essay guidance.
    ///
    /// - Parameter subject: The EE subject, e.g. "Biology".
    /// - Returns: A system prompt string.
    static func systemPrompt(
        subject: String,
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
        你是一位 IB 拓展论文（Extended Essay）指导专家。

        科目：\(subject)

        你帮助：
        1. 构建研究问题
        2. 规划论文结构
        3. 撰写反思（RPPF: 初稿、中期、终稿）
        4. 评估论证质量
        5. 提供导师会议建议

        EE 要求：
        - 最多 4000 字
        - 正式学术写作
        - 引用所有来源
        - 清晰的研究方法
        - 个人参与反思

        评估标准：
        A: 关注点与探究 (Focus and Research Question)
        B: 知识与理解 (Knowledge and Understanding)
        C: 批判性思维 (Critical Thinking)
        D: 展示 (Presentation)
        E: 参与过程 (Engagement - RPPF)
        F: 清晰与语言 (Subject-specific clarity)

        提供具体、可操作的建议，并引用 IB 标准和评分描述。
        语言要求：\(languageInstruction)。
        """
    }

    /// Builds the user prompt for a specific EE stage.
    ///
    /// - Parameters:
    ///   - content: The student's essay draft, notes, or outline.
    ///   - stage: One of "planning", "researching", "drafting", or "reflecting".
    /// - Returns: A user prompt string.
    static func userPrompt(
        content: String,
        stage: String
    ) -> String {
        let stageInstruction: String
        switch stage {
        case "planning":
            stageInstruction = """
            帮助发展研究问题，建议论文结构和研究方向。

            具体任务：
            1. 评估当前研究问题的范围和可行性
            2. 建议改进问题使其更具分析性
            3. 推荐可能的研究方法和资料来源
            4. 提供大纲结构建议
            5. 标注常见的 IB EE 陷阱
            """
        case "researching":
            stageInstruction = """
            评估研究方法，建议额外资料来源，优化论证。

            具体任务：
            1. 评估当前研究方法的合理性
            2. 指出研究中的偏见或局限性
            3. 建议额外的原始和二手资料来源
            4. 帮助整合不同来源的证据
            5. 确保论证符合 IB 学术诚信标准
            """
        case "drafting":
            stageInstruction = """
            审阅草稿内容，评估论证质量，提供改进建议。

            具体任务：
            1. 评估论证结构和逻辑连贯性
            2. 检查是否符合 A-F 评估标准
            3. 标注需要加强批判性思维的部分
            4. 检查引用和参考文献格式
            5. 评估字数分配是否合理
            """
        case "reflecting":
            stageInstruction = """
            帮助撰写 RPPF 反思，关注个人参与和学习过程。

            具体任务：
            1. 引导反思研究过程中的关键决策
            2. 帮助表达方法论选择背后的思考
            3. 反思遇到的挑战和应对方式
            4. 评估研究技能的发展
            5. 确保反思真实、具体、有深度
            """
        default:
            stageInstruction = """
            提供建设性反馈和建议，关注 IB EE 评估标准。
            """
        }

        return """
        \(stageInstruction)

        论文内容/笔记：
        \(content)
        """
    }
}
