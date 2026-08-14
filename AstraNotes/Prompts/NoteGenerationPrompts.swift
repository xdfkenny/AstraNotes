import Foundation

// MARK: - NoteGenerationPrompts
// Prompt templates for generating structured IB study notes from lecture
// transcriptions.  The system prompt instructs the model to produce
// Obsidian-compatible Markdown with YAML front-matter, LaTeX formulas,
// Mermaid diagrams, and HTML fallbacks for complex visualizations.

enum NoteGenerationPrompts {

    /// Builds the system prompt that establishes the AI persona and output
    /// format requirements for note generation.
    ///
    /// - Parameters:
    ///   - subjectName: The IB subject name, e.g. "Biology".
    ///   - level: The display string for the IB level ("HL" or "SL").
    ///   - teacher: The teacher's name.
    ///   - style: One of "detailed", "concise", or "exam-focused".
    /// - Returns: A fully-formed system prompt string.
    static func systemPrompt(
        subjectName: String,
        level: String,
        teacher: String,
        style: String,
        outputLanguage: String = "auto"
    ) -> String {
        let useEnglish = ["en", "es", "fr", "de", "pt", "it", "nl"].contains(outputLanguage)

        let styleDescription: String
        switch style {
        case "detailed":
            styleDescription = useEnglish ? "Comprehensive and thorough" : "详尽全面 (comprehensive and thorough)"
        case "concise":
            styleDescription = useEnglish ? "Concise and summarized" : "精简概括 (concise and summarized)"
        case "exam-focused":
            styleDescription = useEnglish ? "Exam-oriented with past-paper alignment" : "以考试为核心 (exam-oriented with past-paper alignment)"
        default:
            styleDescription = useEnglish ? "Comprehensive and thorough" : "详尽全面 (comprehensive and thorough)"
        }

        let languageInstruction: String
        switch outputLanguage {
        case "auto":
            languageInstruction = useEnglish
                ? "Language: Match the lecture language."
                : "语言：与讲座语言一致。"
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
                ? "Language: All content MUST be output in \(languageName), including titles, descriptions, analysis, and all annotations."
                : "语言：所有内容必须使用 \(languageName) 输出，包括标题、说明、分析和所有注释。"
        }

        if useEnglish {
            return """
            You are a senior academic note-taking expert specializing in International Baccalaureate (IB) courses.

            Given a lecture transcription for \(subjectName) \(level), generate comprehensive study notes.
            Style preference: \(styleDescription)
            Teacher: \(teacher)

            Requirements:
            1. Structure: Title → Learning Objectives → Summary → Core Concepts → Formulas/Diagrams → Study Questions → Related Topics
            2. Formulas: Use LaTeX — inline with $...$, block-level with $$...$$
            3. Diagrams: Use Mermaid syntax inside ```mermaid code blocks:
               - Concept maps (graph TD)
               - Flowcharts (flowchart LR)
               - Comparison diagrams (graph LR with subgraph)
               - Timelines (timeline)
            4. Tables: Use Markdown tables for comparisons, data, definitions
            5. HTML: For complex visualizations that Mermaid cannot handle, use ```html code blocks with inline CSS (max-width 600px)
            6. Exam tips: Include IB exam-relevant tips marked with 💡
            7. Difficulty: Mark HL-only content with [HL] tags

            Output format: Valid Obsidian-flavored Markdown with YAML front-matter.
            \(languageInstruction)
            """
        } else {
            return """
            你是一位专注于国际文凭（IB）课程的资深学术笔记专家。

            给定 \(subjectName) \(level) 的讲座转录，生成全面的学习笔记。
            风格偏好：\(styleDescription)
            教师：\(teacher)

            要求：
            1. 结构：标题 → 学习目标 → 摘要 → 核心概念 → 公式/图表 → 学习问题 → 相关主题
            2. 公式：使用 LaTeX，行内用 $...$，块级用 $$...$$
            3. 图表：在 ```mermaid 代码块中使用 Mermaid 语法绘制：
               - 概念图（graph TD）
               - 流程图（flowchart LR）
               - 对比图（graph LR 配合 subgraph）
               - 时间线（timeline）
            4. 表格：使用 Markdown 表格进行对比、数据、定义
            5. HTML：对于 Mermaid 无法实现的复杂可视化，使用 ```html 代码块及内联 CSS（最大宽度 600px）
            6. 考试技巧：包含与 IB 考试相关的技巧，用 💡 标记
            7. 难度：HL 专属内容用 [HL] 标签标注

            输出格式：有效的 Obsidian 风格 Markdown，含 YAML 前置元数据。
            \(languageInstruction)
            """
        }
    }

    /// Builds the user prompt that wraps the raw lecture transcription with
    /// contextual metadata (subject, level, duration).
    ///
    /// - Parameters:
    ///   - transcription: The raw text transcription of the lecture.
    ///   - subjectName: The IB subject name.
    ///   - level: The display string for the IB level.
    ///   - duration: The lecture duration in seconds.
    /// - Returns: A fully-formed user prompt string.
    static func userPrompt(
        transcription: String,
        subjectName: String,
        level: String,
        duration: TimeInterval,
        outputLanguage: String = "auto"
    ) -> String {
        let durationMinutes = Int(duration / 60)
        let durationStr = "\(durationMinutes) min"
        let useEnglish = ["en", "es", "fr", "de", "pt", "it", "nl"].contains(outputLanguage)

        if useEnglish {
            return """
            Generate study notes from the following lecture transcription:

            Subject: \(subjectName) \(level)
            Lecture duration: \(durationStr)

            ## Transcript:
            \(transcription)
            """
        } else {
            return """
            请根据以下讲座转录生成学习笔记：

            科目：\(subjectName) \(level)
            讲座时长：\(durationStr)

            ## 转录内容：
            \(transcription)
            """
        }
    }
}
