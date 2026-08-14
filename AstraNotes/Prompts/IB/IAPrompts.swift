import Foundation

// MARK: - IAPrompts
// Prompt templates for IB Internal Assessment (IA) guidance.
// Provides subject-group-specific structural templates and tailored
// feedback for IA planning, drafting, and revision.

enum IAPrompts {

    /// Builds the system prompt for Internal Assessment guidance.
    ///
    /// - Parameters:
    ///   - subject: The IA subject, e.g. "Biology".
    ///   - group: The IB subject group number (1-6).
    /// - Returns: A system prompt string.
    static func systemPrompt(
        subject: String,
        group: Int,
        outputLanguage: String = "auto"
    ) -> String {
        let template = Self.iaTemplate(group: group, english: ["en", "es", "fr", "de", "pt", "it", "nl"].contains(outputLanguage))

        let languageInstruction: String
        switch outputLanguage {
        case "auto":
            languageInstruction = ["en", "es", "fr", "de", "pt", "it", "nl"].contains(outputLanguage)
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
            let useEnglish = ["en", "es", "fr", "de", "pt", "it", "nl"].contains(outputLanguage)
            languageInstruction = useEnglish
                ? "Language: All content MUST be output in \(languageName)."
                : "所有内容必须使用 \(languageName) 输出"
        }

        let useEnglish = ["en", "es", "fr", "de", "pt", "it", "nl"].contains(outputLanguage)

        if useEnglish {
            return """
            You are an IB Internal Assessment (IA) guidance expert.

            Subject: \(subject) (Group \(group))

            Template structure:
            \(template)

            You help with:
            1. Planning IA structure
            2. Developing exploration/investigation questions
            3. Writing personal engagement reflections
            4. Evaluating analysis and conclusion quality
            5. Ensuring alignment with IB marking criteria

            Provide specific, actionable advice referencing IB standards and mark descriptors.
            \(languageInstruction).
            """
        } else {
            return """
            你是一位 IB 内部评估（Internal Assessment）指导专家。

            科目：\(subject)（第 \(group) 组）

            模板结构：
            \(template)

            你帮助：
            1. 规划 IA 结构
            2. 发展探索/调查问题
            3. 撰写个人参与反思
            4. 评估分析和结论质量
            5. 确保符合 IB 评分标准

            提供具体、可操作的建议，引用 IB 标准和评分描述。
            语言要求：\(languageInstruction)。
            """
        }
    }

    /// Builds the user prompt for IA feedback.
    ///
    /// - Parameter content: The student's IA draft, notes, or outline.
    /// - Returns: A user prompt string.
    static func userPrompt(
        content: String,
        outputLanguage: String = "auto"
    ) -> String {
        let useEnglish = ["en", "es", "fr", "de", "pt", "it", "nl"].contains(outputLanguage)

        if useEnglish {
            return """
            Review the following Internal Assessment content and provide constructive feedback:

            Specific tasks:
            1. Evaluate the completeness and logical flow of the current structure
            2. Check whether analysis is thorough (personal engagement, depth of exploration)
            3. Highlight sections needing improvement
            4. Suggest additional analytical methods or sources
            5. Assess alignment with IB marking criteria

            IA content:
            \(content)
            """
        } else {
            return """
            审阅以下内部评估内容，提供建设性反馈：

            具体任务：
            1. 评估当前结构的完整性和逻辑性
            2. 检查分析是否充分（个人参与、探索深度）
            3. 标注需要改进的部分
            4. 建议额外的分析方法或资料来源
            5. 评估是否符合 IB 评分标准

            IA 内容：
            \(content)
            """
        }
    }

    // MARK: - Group-Specific IA Templates

    /// Returns the recommended IA section structure for a given subject group.
    ///
    /// - Parameter group: The IB subject group number (1-6).
    /// - Returns: A formatted template string.
    static func iaTemplate(group: Int, english: Bool = false) -> String {
        switch group {
        case 4: // Group 4: Sciences (Biology, Chemistry, Physics, etc.)
            if english {
                return """
                1. Personal Engagement & Exploration
                   - Reason for choosing this research question
                   - Background information and research context
                   - Research Question (RQ)
                2. Exploration & Analysis
                   - Variable definitions (independent, dependent, controlled)
                   - Methodology description
                   - Data collection and processing
                   - Uncertainty analysis
                   - Graphs and statistical analysis
                3. Evaluation
                   - Methodology limitations
                   - Data reliability
                   - Improvement suggestions
                4. Conclusion
                   - Research question response
                   - Comparison with scientific theories
                """
            }
            return """
            1. 个人参与与探索（Personal Engagement & Exploration）
               - 选择该研究问题的原因
               - 背景信息与研究背景
               - 研究问题 (RQ)
            2. 探索与分析（Exploration & Analysis）
               - 变量定义（自变量、因变量、控制变量）
               - 方法论描述
               - 数据收集与处理
               - 不确定度分析
               - 图表与统计分析
            3. 评估（Evaluation）
               - 方法论局限性
               - 数据可靠性
               - 改进建议
            4. 结论（Conclusion）
               - 研究问题回应
               - 与科学理论的比较
            """

        case 5: // Group 5: Mathematics
            if english {
                return """
                1. Introduction & Motivation
                   - Reason for choosing this topic
                   - Goals and plan
                2. Mathematical Exploration
                   - Notation and terminology definitions
                   - Mathematical derivation and calculation
                   - Graphs and visualisations
                   - Use of technological tools
                3. Generalisation & Verification
                   - Generalisation of results
                   - Testing edge cases
                   - Comparison with known mathematical results
                4. Conclusion
                   - Summary of findings
                   - Reflection on the mathematical process
                   - Directions for future exploration
                """
            }
            return """
            1. 引言与动机（Introduction & Motivation）
               - 选择主题的原因
               - 目标与计划
            2. 数学探索（Mathematical Exploration）
               - 符号与术语定义
               - 数学推导与计算
               - 图表与可视化
               - 技术工具的使用
            3. 推广与验证（Generalization & Verification）
               - 结果的推广
               - 极限情况检验
               - 与已知的数学结果比较
            4. 结论（Conclusion）
               - 总结发现
               - 反思数学过程
               - 未来探索方向
            """

        case 1: // Group 1: Studies in Language and Literature
            if english {
                return """
                1. Work Selection & Rationale
                   - Selected works and rationale
                   - Literary background and context
                2. Textual Analysis
                   - Themes and motifs
                   - Literary devices and techniques
                   - Language and style analysis
                3. Argument & Evidence
                   - Main arguments
                   - Textual evidence support
                   - Counter-arguments
                4. Conclusion
                   - Argument summary
                   - Broader significance
                """
            }
            return """
            1. 作品选择与理由
               - 选定作品及理由
               - 文学背景与语境
            2. 文本分析
               - 主题与 motifs
               - 文学手法与技巧
               - 语言与风格分析
            3. 论证与证据
               - 主要论点
               - 文本证据支持
               - 反驳观点
            4. 结论
               - 论点总结
               - 更广泛的意义
            """

        case 3: // Group 3: Individuals and Societies
            if english {
                return """
                1. Research Question & Scope
                   - Research Question (RQ)
                   - Geographic/temporal scope
                   - Key concept definitions
                2. Investigation Methods
                   - Research method selection
                   - Data sources (primary/secondary)
                   - Methodology limitations
                3. Analysis & Discussion
                   - Key findings
                   - Different perspectives and interpretations
                   - Theoretical framework integration
                4. Conclusion
                   - Research question response
                   - Policy/practice recommendations
                   - Directions for future research
                """
            }
            return """
            1. 研究问题与范围
               - 研究问题 (RQ)
               - 地理/时间范围
               - 关键概念定义
            2. 调查方法
               - 研究方法选择
               - 数据来源（原始/二手）
               - 方法论局限性
            3. 分析与讨论
               - 主要发现
               - 不同视角与解释
               - 理论框架整合
            4. 结论
               - 研究问题回应
               - 政策/实践建议
               - 未来研究方向
            """

        case 2: // Group 2: Language Acquisition
            if english {
                return """
                1. Introduction
                   - Selected topic and rationale
                   - Target culture/language background
                2. Description & Analysis
                   - Cultural product analysis
                   - Language feature analysis
                   - Comparison/contrast
                3. Conclusion
                   - Key findings
                   - Cultural insights
                """
            }
            return """
            1. 引言
               - 选定主题及理由
               - 目标文化/语言背景
            2. 描述与分析
               - 文化产品分析
               - 语言特征分析
               - 比较/对比
            3. 结论
               - 主要发现
               - 文化洞察
            """

        case 6: // Group 6: The Arts
            if english {
                return """
                1. Introduction
                   - Artwork/performance selection
                   - Research focus
                2. Analysis
                   - Form and structure
                   - Techniques and materials
                   - Context and influence
                3. Comparison/Contrast
                   - Different works/artists
                   - Common themes
                4. Conclusion
                   - Artistic evaluation
                   - Personal reflection
                """
            }
            return """
            1. 引言
               - 艺术作品/表演选择
               - 研究焦点
            2. 分析
               - 形式与结构
               - 技术与材料
               - 语境与影响
            3. 比较/对比
               - 不同作品/艺术家
               - 共同主题
            4. 结论
               - 艺术评价
               - 个人反思
            """

        default:
            if english {
                return """
                1. Introduction
                   - Topic selection and research scope
                2. Exploration/Investigation
                   - Research methodology and analysis
                3. Analysis
                   - Findings and discussion
                4. Conclusion
                   - Summary and reflection
                """
            }
            return """
            1. 引言
               - 主题选择与研究范围
            2. 探索/调查
               - 研究方法与分析
            3. 分析
               - 发现与讨论
            4. 结论
               - 总结与反思
            """
        }
    }
}
