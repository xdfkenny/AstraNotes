// MarkdownRenderer.swift — AstraNotes
// Preview renderer using WKWebView for displaying markdown content.
// Supports Mermaid diagrams, LaTeX math, and HTML rendering with the
// Astra theme. Includes print/export support.

import SwiftUI
import WebKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Markdown Renderer

@Observable
final class MarkdownRenderer: NSObject {

    // MARK: - Properties

    var htmlContent: String = ""
    var isLoading: Bool = false

    private var webView: WKWebView?

    // MARK: - Rendering

    /// Converts a markdown string into a fully themed HTML document.
    func renderMarkdown(_ markdown: String, isDark: Bool) -> String {
        var html = markdown

        // Strip YAML frontmatter if present
        html = stripFrontmatter(from: html)

        // Apply markdown-to-HTML conversions
        html = convertHeaders(html)
        html = convertInlineFormatting(html)
        html = convertCodeBlocks(html)
        html = convertBlockquotes(html)
        html = convertLists(html)
        html = convertTables(html)
        html = convertHorizontalRules(html)
        html = convertWikilinks(html)

        // Wrap paragraphs around loose text
        html = wrapInParagraphs(html)

        return wrapInThemeHTML(html, isDark: isDark)
    }

    // MARK: - Frontmatter Stripping

    private func stripFrontmatter(from markdown: String) -> String {
        guard markdown.hasPrefix("---") else { return markdown }

        let lines = markdown.components(separatedBy: "\n")
        guard lines.count > 2 else { return markdown }

        // Find the closing ---
        var endIndex = 1
        for i in 1..<lines.count where lines[i] == "---" {
            endIndex = i
            break
        }

        if endIndex < lines.count - 1 {
            return lines[(endIndex + 1)...].joined(separator: "\n")
        }
        return markdown
    }

    // MARK: - Markdown Conversion

    private func convertHeaders(_ html: String) -> String {
        var result = html
        // Process in reverse order so ### is not caught by ##
        result = result.replacingOccurrences(
            of: #"^#### (.*$)"#,
            with: "<h4>$1</h4>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"^### (.*$)"#,
            with: "<h3>$1</h3>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"^## (.*$)"#,
            with: "<h2>$1</h2>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"^# (.*$)"#,
            with: "<h1>$1</h1>",
            options: .regularExpression
        )
        return result
    }

    private func convertInlineFormatting(_ html: String) -> String {
        var result = html
        // Bold + italic
        result = result.replacingOccurrences(
            of: #"\*\*\*(.*?)\*\*\*"#,
            with: "<strong><em>$1</em></strong>",
            options: .regularExpression
        )
        // Bold
        result = result.replacingOccurrences(
            of: #"\*\*(.*?)\*\*"#,
            with: "<strong>$1</strong>",
            options: .regularExpression
        )
        // Italic
        result = result.replacingOccurrences(
            of: #"\*(.*?)\*"#,
            with: "<em>$1</em>",
            options: .regularExpression
        )
        // Inline code
        result = result.replacingOccurrences(
            of: #"`(.*?)`"#,
            with: "<code>$1</code>",
            options: .regularExpression
        )
        // Strikethrough
        result = result.replacingOccurrences(
            of: #"~~(.*?)~~"#,
            with: "<del>$1</del>",
            options: .regularExpression
        )
        return result
    }

    private func convertCodeBlocks(_ html: String) -> String {
        var result = html
        // Fenced code blocks with language hint
        result = result.replacingOccurrences(
            of: #"```(\w*)\n([\s\S]*?)```"#,
            with: "<pre><code class=\"language-$1\">$2</code></pre>",
            options: .regularExpression
        )
        // Fenced code blocks without language hint
        result = result.replacingOccurrences(
            of: #"```\n([\s\S]*?)```"#,
            with: "<pre><code>$1</code></pre>",
            options: .regularExpression
        )
        return result
    }

    private func convertBlockquotes(_ html: String) -> String {
        var result = html
        // Multi-line blockquotes: collapse consecutive > lines
        result = result.replacingOccurrences(
            of: #"((?:^> .*$(?:\n|\z))+)"#,
            with: { match in
                let lines = match.output
                    .components(separatedBy: .newlines)
                    .map { $0.replacingOccurrences(of: "> ", with: "") }
                    .filter { !$0.isEmpty }
                let inner = lines.joined(separator: "<br>")
                return "<blockquote>\(inner)</blockquote>"
            },
            options: .regularExpression
        )
        // Single-line blockquotes
        result = result.replacingOccurrences(
            of: #"^> (.*$)"#,
            with: "<blockquote>$1</blockquote>",
            options: .regularExpression
        )
        return result
    }

    private func convertLists(_ html: String) -> String {
        var result = html

        // Unordered list items
        result = result.replacingOccurrences(
            of: #"^(\s*)- (.*$)"#,
            with: "$1<li>$2</li>",
            options: .regularExpression
        )

        // Ordered list items
        result = result.replacingOccurrences(
            of: #"^(\s*)\d+\. (.*$)"#,
            with: "$1<li>$2</li>",
            options: .regularExpression
        )

        // Wrap consecutive <li> items in <ul>
        result = result.replacingOccurrences(
            of: #"((?:<li>.*</li>\n?)+)"#,
            with: { match in
                let items = match.output.trimmingCharacters(in: .whitespacesAndNewlines)
                return "<ul>\n\(items)\n</ul>"
            },
            options: .regularExpression
        )

        return result
    }

    private func convertTables(_ html: String) -> String {
        var result = html
        var lines = result.components(separatedBy: .newlines)
        var inTable = false
        var tableLines: [String] = []
        var outputLines: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") {
                // Skip separator lines (|---|---|)
                let stripped = trimmed
                    .trimmingCharacters(in: CharacterSet(charactersIn: "|"))
                    .trimmingCharacters(in: .whitespaces)
                if stripped.allSatisfy({ $0 == "-" || $0 == ":" || $0 == " " }) {
                    if inTable {
                        // End of header separator, continue body
                        continue
                    }
                    continue
                }
                inTable = true
                // Convert to table row
                let cells = trimmed
                    .trimmingCharacters(in: CharacterSet(charactersIn: "|"))
                    .components(separatedBy: "|")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                let cellTags = cells.map { "<td>\($0)</td>" }.joined()
                tableLines.append("<tr>\(cellTags)</tr>")
            } else {
                if inTable {
                    // Close the table
                    outputLines.append("<table>")
                    // Make first row header
                    if !tableLines.isEmpty {
                        let headerRow = tableLines[0]
                            .replacingOccurrences(of: "<td>", with: "<th>")
                            .replacingOccurrences(of: "</td>", with: "</th>")
                        outputLines.append(headerRow)
                        for i in 1..<tableLines.count {
                            outputLines.append(tableLines[i])
                        }
                    }
                    outputLines.append("</table>")
                    tableLines = []
                    inTable = false
                }
                outputLines.append(line)
            }
        }

        // Close any remaining open table
        if inTable && !tableLines.isEmpty {
            outputLines.append("<table>")
            let headerRow = tableLines[0]
                .replacingOccurrences(of: "<td>", with: "<th>")
                .replacingOccurrences(of: "</td>", with: "</th>")
            outputLines.append(headerRow)
            for i in 1..<tableLines.count {
                outputLines.append(tableLines[i])
            }
            outputLines.append("</table>")
        }

        return outputLines.joined(separator: "\n")
    }

    private func convertHorizontalRules(_ html: String) -> String {
        html.replacingOccurrences(
            of: #"^(---|\*\*\*|___)\s*$"#,
            with: "<hr>",
            options: .regularExpression
        )
    }

    private func convertWikilinks(_ html: String) -> String {
        html.replacingOccurrences(
            of: #"\[\[([^\]|]+)(?:\|([^\]]+))?\]\]"#,
            with: "<a class=\"wikilink\" href=\"$1\">$2</a>",
            options: .regularExpression
        )
    }

    private func wrapInParagraphs(_ html: String) -> String {
        // A simple heuristic: wrap lines that are not already HTML tags
        // and are not empty in <p> tags
        let lines = html.components(separatedBy: .newlines)
        var result: [String] = []
        var inParagraph = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                if inParagraph {
                    result.append("</p>")
                    inParagraph = false
                }
                result.append("")
                continue
            }

            // Skip if line already starts with an HTML block-level tag
            let blockTags = ["<h1", "<h2", "<h3", "<h4", "<ul", "<ol", "<li",
                             "<blockquote", "<pre", "<table", "<tr", "<hr",
                             "</ul", "</ol", "</table", "</blockquote", "</pre"]
            let isBlockTag = blockTags.contains { trimmed.hasPrefix($0) }

            if isBlockTag {
                if inParagraph {
                    result.append("</p>")
                    inParagraph = false
                }
                result.append(trimmed)
            } else if !trimmed.hasPrefix("<") {
                if !inParagraph {
                    result.append("<p>\(trimmed)")
                    inParagraph = true
                } else {
                    result.append("<br>\(trimmed)")
                }
            } else {
                result.append(trimmed)
            }
        }

        if inParagraph {
            result.append("</p>")
        }

        return result.joined(separator: "\n")
    }

    // MARK: - Theme HTML Wrapper

    private func wrapInThemeHTML(_ bodyContent: String, isDark: Bool) -> String {
        let bgColor = isDark ? "#131316" : "#F7F7F8"
        let textColor = isDark ? "#F2F2F4" : "#1A1A1E"
        let cardBg = isDark ? "#1C1C1F" : "#FFFFFF"
        let codeBg = isDark ? "#242428" : "#F0F0F2"
        let accentColor = isDark ? "#59C9B8" : "#0B7A6E"
        let borderColor = isDark ? "#FFFFFF" : "#000000"
        let mutedColor = isDark ? "#A0A0AA" : "#5C5C66"

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>AstraNotes Preview</title>
            <style>
                :root {
                    --bg: \(bgColor);
                    --text: \(textColor);
                    --card-bg: \(cardBg);
                    --code-bg: \(codeBg);
                    --accent: \(accentColor);
                    --border: \(borderColor);
                    --muted: \(mutedColor);
                }

                @media print {
                    body { padding: 0; background: white; color: black; }
                    pre { border: 1px solid #ddd; }
                }

                * { margin: 0; padding: 0; box-sizing: border-box; }

                body {
                    font-family: -apple-system, 'PingFang SC', 'Microsoft YaHei', BlinkMacSystemFont, sans-serif;
                    font-size: 16px;
                    line-height: 1.7;
                    color: var(--text);
                    background-color: var(--bg);
                    padding: 32px;
                    max-width: 800px;
                    margin: 0 auto;
                }

                h1 {
                    font-size: 2rem;
                    font-weight: 700;
                    margin: 28px 0 16px;
                    color: var(--text);
                    letter-spacing: -0.02em;
                }
                h2 {
                    font-size: 1.5rem;
                    font-weight: 600;
                    margin: 24px 0 12px;
                    color: var(--text);
                    border-bottom: 1px solid var(--border);
                    padding-bottom: 8px;
                }
                h3 {
                    font-size: 1.25rem;
                    font-weight: 600;
                    margin: 20px 0 8px;
                    color: var(--text);
                }
                h4 {
                    font-size: 1.1rem;
                    font-weight: 600;
                    margin: 16px 0 6px;
                    color: var(--muted);
                }

                p { margin: 12px 0; }

                strong { color: var(--accent); font-weight: 600; }
                em { font-style: italic; }
                del { opacity: 0.5; text-decoration: line-through; }

                a {
                    color: var(--accent);
                    text-decoration: none;
                    border-bottom: 1px solid transparent;
                    transition: border-color 0.2s;
                }
                a:hover { border-bottom-color: var(--accent); }
                a.wikilink { color: var(--accent); }

                blockquote {
                    border-left: 3px solid var(--accent);
                    padding: 12px 16px;
                    margin: 16px 0;
                    background: var(--card-bg);
                    border-radius: 8px;
                    color: var(--muted);
                    font-style: italic;
                }

                pre {
                    background: var(--code-bg);
                    border: 1px solid var(--border);
                    border-radius: 12px;
                    padding: 16px;
                    overflow-x: auto;
                    margin: 16px 0;
                    line-height: 1.5;
                }

                code {
                    font-family: 'JetBrains Mono', 'Fira Code', 'SF Mono', 'Menlo', monospace;
                    font-size: 0.875rem;
                    background: var(--code-bg);
                    padding: 2px 6px;
                    border-radius: 4px;
                }

                pre code {
                    background: transparent;
                    padding: 0;
                    border-radius: 0;
                }

                li { margin: 4px 0; padding-left: 4px; }
                ul, ol { padding-left: 24px; margin: 8px 0; }

                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 16px 0;
                    border-radius: 8px;
                    overflow: hidden;
                    border: 1px solid var(--border);
                }
                td, th {
                    padding: 10px 14px;
                    border: 1px solid var(--border);
                    text-align: left;
                }
                th {
                    background: var(--code-bg);
                    font-weight: 600;
                    font-size: 0.875rem;
                    text-transform: uppercase;
                    letter-spacing: 0.04em;
                    color: var(--muted);
                }
                tr:nth-child(even) { background: var(--card-bg); }

                .mermaid {
                    margin: 20px 0;
                    text-align: center;
                    padding: 16px;
                    background: var(--card-bg);
                    border-radius: 12px;
                    border: 1px solid var(--border);
                }

                hr {
                    border: none;
                    border-top: 1px solid var(--border);
                    margin: 28px 0;
                }

                img {
                    max-width: 100%;
                    border-radius: 8px;
                    margin: 12px 0;
                }
            </style>
            <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
            <script>
                mermaid.initialize({
                    startOnLoad: true,
                    theme: '\(isDark ? "dark" : "default")',
                    themeVariables: {
                        primaryColor: '\(accentColor)',
                        primaryTextColor: '\(textColor)',
                        lineColor: '\(accentColor)',
                        background: '\(cardBg)'
                    }
                });
            </script>
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
            <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
            <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js"
                    onload="renderMathInElement(document.body, {
                        delimiters: [
                            {left: '$$', right: '$$', display: true},
                            {left: '$', right: '$', display: false}
                        ]
                    });"></script>
        </head>
        <body>
            \(bodyContent)
        </body>
        </html>
        """
    }

    // MARK: - Print Support

    /// Generates a print-friendly HTML string from the given markdown.
    func renderForPrint(_ markdown: String) -> String {
        var html = renderMarkdown(markdown, isDark: false)
        // Inject print-specific styles
        html = html.replacingOccurrences(
            of: "</head>",
            with: """
            <style>
                @media print {
                    body { padding: 20mm; background: white !important; color: black !important; max-width: 100%; }
                    pre, code { border-color: #ddd !important; background: #f5f5f5 !important; color: black !important; }
                    blockquote { border-color: #999 !important; color: #555 !important; }
                    a { color: #0066cc !important; }
                }
            </style>
            </head>
            """
        )
        return html
    }
}

// MARK: - Markdown Preview (SwiftUI Wrapper)

/// A SwiftUI view that wraps WKWebView for rendering markdown with the Astra theme.
#if os(macOS)
struct MarkdownPreview: NSViewRepresentable {

    let markdown: String
    let isDark: Bool

    func makeNSView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = preferences
        config.userContentController.add(context.coordinator, name: "markdownRenderer")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.underPageBackgroundColor = .clear

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        let renderer = MarkdownRenderer()
        let html = renderer.renderMarkdown(markdown, isDark: isDark)
        nsView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

        var onLoadingChanged: ((Bool) -> Void)?

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onLoadingChanged?(false)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            onLoadingChanged?(true)
        }

        // MARK: - WKScriptMessageHandler

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            // Handle JavaScript-to-Swift bridge messages if needed
        }
    }
}
#else
struct MarkdownPreview: UIViewRepresentable {

    let markdown: String
    let isDark: Bool

    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = preferences
        config.userContentController.add(context.coordinator, name: "markdownRenderer")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let renderer = MarkdownRenderer()
        let html = renderer.renderMarkdown(markdown, isDark: isDark)
        uiView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

        var onLoadingChanged: ((Bool) -> Void)?

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onLoadingChanged?(false)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            onLoadingChanged?(true)
        }

        // MARK: - WKScriptMessageHandler

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            // Handle JavaScript-to-Swift bridge messages if needed
        }
    }
}
#endif

// MARK: - Markdown Preview with Export

/// Extended MarkdownPreview that supports printing and PDF export.
struct MarkdownPreviewWithExport: View {

    let markdown: String
    var isDark: Bool = false

    @State private var webView: WKWebView?
    @State private var showExportPanel: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            MarkdownPreview(markdown: markdown, isDark: isDark)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    exportToPDF()
                } label: {
                    Label { Text("Export PDF") } icon: { AstraIconView(.download, size: 12) }
                }

                Button {
                    printContent()
                } label: {
                    Label { Text("Print") } icon: { AstraIconView(.print, size: 12) }
                }
            }
        }
    }

    // MARK: - Export

    private func exportToPDF() {
        guard let webView = webView else { return }

        #if os(macOS)
        guard let window = webView.window else { return }

        let panel = NSSavePanel()
        panel.title = "Export PDF"
        panel.nameFieldStringValue = "AstraNotes_Note.pdf"
        panel.allowedContentTypes = [.pdf]

        if panel.runModal() == .OK, let url = panel.url {
            let pdfData = webView.dataForPDF()
            do {
                try pdfData?.write(to: url)
            } catch {
                print("Failed to export PDF: \(error)")
            }
        }
        #else
        let renderer = UIGraphicsImageRenderer(bounds: webView.bounds)
        let image = renderer.image { ctx in
            webView.drawHierarchy(in: webView.bounds, afterScreenUpdates: true)
        }
        guard let pdfData = image.pngData() else { return }

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            let activityVC = UIActivityViewController(activityItems: [pdfData], applicationActivities: nil)
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            }
            rootVC.present(activityVC, animated: true)
        }
        #endif
    }

    private func printContent() {
        #if os(macOS)
        webView?.print(nil)
        #else
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "AstraNotes"
        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.printingItem = webView?.snapshot()
        printController.present(animated: true)
        #endif
    }
}
