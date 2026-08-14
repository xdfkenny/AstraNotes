import Foundation

// MARK: - CASPrompts
// Prompt templates for IB Creativity, Activity, Service (CAS) reflection.
// Guides students through meaningful reflection tied to the seven CAS
// learning outcomes, with support for planning and outcome identification.

enum CASPrompts {

    /// The seven CAS learning outcomes as defined by the IB.
    static let learningOutcomes: [String] = [
        "识别自身优势和成长领域",
        "展示应对新挑战和发展新技能",
        "规划和发起 CAS 体验",
        "展示坚持和承诺",
        "展示合作技能并认识其益处",
        "参与具有全球意义的问题",
        "认识和考虑选择和行动的伦理"
    ]

    /// English versions of the seven CAS learning outcomes.
    static let learningOutcomesEnglish: [String] = [
        "Identify own strengths and areas of growth",
        "Demonstrate that challenges have been undertaken, developing new skills",
        "Demonstrate how to initiate and plan a CAS experience",
        "Show commitment to and perseverance in CAS experiences",
        "Demonstrate the skills and recognize the benefits of collaborative work",
        "Engage with issues of global significance",
        "Recognize and consider the ethics of choices and actions"
    ]

    /// Builds the system prompt for CAS reflection and planning.
    ///
    /// - Returns: A system prompt string.
    static func systemPrompt(outputLanguage: String = "auto") -> String {
        let useEnglish = ["en", "es", "fr", "de", "pt", "it", "nl"].contains(outputLanguage)

        let outcomes = useEnglish ? learningOutcomesEnglish : learningOutcomes
        let outcomesList = outcomes.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        let languageInstruction: String
        switch outputLanguage {
        case "auto":
            languageInstruction = useEnglish
                ? "Language: Match the lecture language."
                : "与讲座语言一致"
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
            languageInstruction = useEnglish
                ? "Language: All content MUST be output in \(languageName)."
                : "所有内容必须使用 \(languageName) 输出"
        }

        if useEnglish {
            return """
            You are an IB Creativity, Activity, Service (CAS) reflection facilitator.

            You help with:
            1. Guiding deep reflection
            2. Linking to the 7 learning outcomes
            3. Identifying personal growth
            4. Writing meaningful activity descriptions

            7 Learning Outcomes:
            \(outcomesList)

            Reflections should:
            - Be sincere, specific, and demonstrate genuine learning and growth
            - Use first person
            - Include specific events and details
            - Link to at least 2-3 learning outcomes
            - Show insights gained from the experience
            - Avoid vague and superficial descriptions
            \(languageInstruction).
            """
        } else {
            return """
            你是一位 IB 创意、活动、服务（CAS）反思引导专家。

            你帮助：
            1. 引导深度反思
            2. 关联 7 项学习成果
            3. 识别个人成长
            4. 撰写有意义的活动描述

            7 项学习成果：
            \(outcomesList)

            反思应：
            - 真诚、具体，展示真实的学习和成长过程
            - 使用第一人称
            - 包含具体事件和细节
            - 关联至少 2-3 项学习成果
            - 展示从经历中获得的洞察
            - 避免空泛和表面化的描述
            语言要求：\(languageInstruction)。
            """
        }
    }

    /// Builds the user prompt for a CAS activity.
    ///
    /// - Parameters:
    ///   - description: The student's description of the activity.
    ///   - category: The CAS strand ("Creativity", "Activity", or "Service"),
    ///     or "Project" for a CAS project.
    ///   - focus: One of "reflection", "planning", or "outcomes".
    /// - Returns: A user prompt string.
    static func userPrompt(
        description: String,
        category: String,
        focus: String,
        outputLanguage: String = "auto"
    ) -> String {
        let useEnglish = ["en", "es", "fr", "de", "pt", "it", "nl"].contains(outputLanguage)

        let focusInstruction: String
        switch focus {
        case "reflection":
            if useEnglish {
                focusInstruction = """
                Write a deep reflection based on the activity description, linking to learning outcomes.

                Specific requirements:
                1. Write a 200-400 word reflection paragraph
                2. Explicitly link 2-3 learning outcomes and explain how they were achieved
                3. Describe specific challenges, decisions, and growth moments
                4. Reflect on the impact of the activity on yourself and others
                5. Look forward to improvements or continuation
                """
            } else {
                focusInstruction = """
                基于活动描述撰写深度反思，关联学习成果。

                具体要求：
                1. 撰写 200-400 字的反思段落
                2. 明确关联 2-3 项学习成果，并说明如何达成
                3. 描述具体的挑战、决定和成长时刻
                4. 反思活动对你个人和他人的影响
                5. 展望未来的改进或延续
                """
            }
        case "planning":
            if useEnglish {
                focusInstruction = """
                Help plan a CAS activity by setting goals and expected outcomes.

                Specific requirements:
                1. Suggest specific, measurable goals
                2. Identify potentially achievable learning outcomes
                3. Suggest activity steps and timeline
                4. Highlight potential challenges and solutions
                5. Recommend documentation and evidence methods
                """
            } else {
                focusInstruction = """
                帮助规划 CAS 活动，设定目标和预期成果。

                具体要求：
                1. 建议具体、可衡量的目标
                2. 识别可能达成的学习成果
                3. 建议活动步骤和时间安排
                4. 提示潜在挑战和解决方案
                5. 推荐记录和证明方式
                """
            }
        case "outcomes":
            if useEnglish {
                focusInstruction = """
                Identify the learning outcomes this activity could achieve and provide linking suggestions.

                Specific requirements:
                1. Evaluate the applicability of each of the 7 learning outcomes
                2. For applicable outcomes, provide specific linking explanations
                3. Suggest how to strengthen weaker outcome links
                4. Recommend additional activities to cover more outcomes
                """
            } else {
                focusInstruction = """
                识别活动可能达成的学习成果，提供关联建议。

                具体要求：
                1. 逐一评估 7 项学习成果的适用性
                2. 对适用的成果提供具体关联说明
                3. 建议如何强化较弱的成果关联
                4. 推荐额外活动以覆盖更多成果
                """
            }
        default:
            if useEnglish {
                focusInstruction = """
                Provide advice and feedback on the CAS activity, focusing on learning outcome connections.
                """
            } else {
                focusInstruction = """
                提供有关 CAS 活动的建议和反馈，关注学习成果关联。
                """
            }
        }

        if useEnglish {
            return """
            \(focusInstruction)

            Activity category: \(category)
            Activity description: \(description)
            """
        } else {
            return """
            \(focusInstruction)

            活动类别：\(category)
            活动描述：\(description)
            """
        }
    }
}
