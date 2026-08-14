import Foundation

// MARK: - MermaidDiagramPrompts
// Prompt templates for generating Mermaid diagrams from text content.
// Supports concept maps, flowcharts, sequence diagrams, timelines,
// pie charts, and Gantt charts.

enum MermaidDiagramPrompts {

    /// Builds the system prompt for Mermaid diagram generation.
    ///
    /// - Returns: A system prompt string.
    static func systemPrompt(outputLanguage: String = "auto") -> String {
        let languageInstruction: String
        switch outputLanguage {
        case "auto":
            languageInstruction = "标签使用用户语言（中文/英文）"
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
            languageInstruction = "所有标签和说明必须使用 \(languageName)"
        }

        return """
        你是一位 Mermaid 图表生成专家。

        从给定的文本中生成 Mermaid 图表。

        支持的图表类型：
        1. graph TD/LR - 概念图、关系图
        2. flowchart TD/LR - 流程图（支持 subgraph）
        3. sequenceDiagram - 时序图
        4. timeline - 时间线
        5. pie - 饼图
        6. gantt - 甘特图

        要求：
        1. 使用清晰的节点标签
        2. 适当的子图分组
        3. 使用样式自定义颜色
        4. 保持图表简洁可读
        5. 每个图表用 ```mermaid 代码块包裹
        6. 节点 ID 使用简洁的英文标识符（如 nodeA, nodeB）
        7. 语言要求：\(languageInstruction)
        """
    }

    /// Builds the user prompt requesting a specific diagram type.
    ///
    /// - Parameters:
    ///   - content: The source text to visualise.
    ///   - diagramType: The requested diagram type, or "auto" to let the
    ///     model choose the best representation.
    /// - Returns: A user prompt string.
    static func userPrompt(
        content: String,
        diagramType: String = "auto"
    ) -> String {
        let typeInstruction: String
        switch diagramType.lowercased() {
        case "concept":
            typeInstruction = "概念图（graph TD）"
        case "flowchart":
            typeInstruction = "流程图（flowchart LR）"
        case "sequence":
            typeInstruction = "时序图（sequenceDiagram）"
        case "timeline":
            typeInstruction = "时间线（timeline）"
        case "pie":
            typeInstruction = "饼图（pie）"
        case "gantt":
            typeInstruction = "甘特图（gantt）"
        case "auto":
            typeInstruction = "最适合该内容的图表类型（自动选择）"
        default:
            typeInstruction = "最适合该内容的图表类型（自动选择）"
        }

        return """
        从以下内容生成\(typeInstruction)类型的 Mermaid 图表：

        \(content)
        """
    }
}
