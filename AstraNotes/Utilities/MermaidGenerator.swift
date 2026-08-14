import Foundation

// MARK: - MermaidGenerator
// Utility enum for generating Mermaid diagram syntax strings.
// Supports concept maps (directed graphs), flowcharts, and comparison
// subgraphs. Output can be wrapped in a markdown code fence for
// direct embedding in generated notes.

enum MermaidGenerator {

    // MARK: - Concept Map

    /// Generates a top-down concept map with labeled nodes and optional
    /// edge labels.
    /// - Parameters:
    ///   - nodes: An array of (id, label) tuples representing graph nodes.
    ///   - edges: An array of (from, to, label?) tuples. When `label` is nil,
    ///            a plain arrow is drawn; otherwise a labeled arrow is used.
    /// - Returns: A complete Mermaid `graph TD` string.
    static func conceptMap(
        nodes: [(id: String, label: String)],
        edges: [(from: String, to: String, label: String?)]
    ) -> String {
        var lines = ["graph TD"]

        for node in nodes {
            lines.append("    \(node.id)[\(node.label)]")
        }

        for edge in edges {
            if let label = edge.label {
                lines.append("    \(edge.from) -->|\(label)| \(edge.to)")
            } else {
                lines.append("    \(edge.from) --> \(edge.to)")
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Flowchart

    /// Generates a left-to-right flowchart with labeled steps.
    /// - Parameters:
    ///   - steps:       An array of (id, label) tuples for each step.
    ///   - connections: An array of (from, to) tuples defining the flow.
    /// - Returns: A complete Mermaid `flowchart LR` string.
    static func flowchart(
        steps: [(id: String, label: String)],
        connections: [(from: String, to: String)]
    ) -> String {
        var lines = ["flowchart LR"]

        for step in steps {
            lines.append("    \(step.id)[\(step.label)]")
        }

        for conn in connections {
            lines.append("    \(conn.from) --> \(conn.to)")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Comparison Subgraph

    /// Generates a comparison diagram with subgraphs for each item.
    /// - Parameter items: An array of (name, properties) tuples. Each item
    ///   becomes a named subgraph containing its properties as nodes.
    /// - Returns: A complete Mermaid `graph LR` string with subgraphs.
    static func comparison(
        items: [(name: String, properties: [String])]
    ) -> String {
        var lines = ["graph LR"]

        for (index, item) in items.enumerated() {
            let id = "item\(index)"
            lines.append("    subgraph \(item.name)")
            for prop in item.properties {
                lines.append("        \(id)_\(prop)[\(prop)]")
            }
            lines.append("    end")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Code Block Wrapper

    /// Wraps a Mermaid diagram string in a markdown fenced code block
    /// for direct embedding in Obsidian-compatible notes.
    /// - Parameter mermaid: The raw Mermaid syntax string.
    /// - Returns: The Mermaid string wrapped in triple-backtick fences.
    static func wrapInCodeBlock(_ mermaid: String) -> String {
        "```mermaid\n\(mermaid)\n```"
    }
}
