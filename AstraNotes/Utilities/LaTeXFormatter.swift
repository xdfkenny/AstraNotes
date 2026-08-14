import Foundation

// MARK: - LaTeXFormatter
// Utility enum for building LaTeX math expressions that can be embedded
// in generated notes (rendered by MathJax in Obsidian). Provides helpers
// for inline and block math, fractions, vectors, summations, integrals,
// and Greek letter shortcuts.

enum LaTeXFormatter {

    // MARK: - Math Modes

    /// Wraps an expression in LaTeX inline math delimiters: `$...$`
    static func inlineMath(_ expression: String) -> String {
        "$\(expression)$"
    }

    /// Wraps an expression in LaTeX display (block) math delimiters: `$$...$$`
    static func blockMath(_ expression: String) -> String {
        "$$\n\(expression)\n$$"
    }

    // MARK: - Structures

    /// Produces a LaTeX fraction: `\frac{numerator}{denominator}`
    static func fraction(_ numerator: String, _ denominator: String) -> String {
        "\\frac{\(numerator)}{\(denominator)}"
    }

    /// Produces a LaTeX vector arrow: `\vec{components}`
    static func vector(_ components: String...) -> String {
        "\\vec{\(components.joined(separator: ", "))}"
    }

    /// Produces a LaTeX summation: `\sum_{lower}^{upper} expression`
    /// - Parameters:
    ///   - lower:     The subscript bound (default `"i=0"`).
    ///   - upper:     The superscript bound (default `"n"`).
    ///   - expression: The expression to sum.
    static func sum(lower: String = "i=0", upper: String = "n", expression: String) -> String {
        "\\sum_{\(lower)}^{\(upper)} \(expression)"
    }

    /// Produces a LaTeX integral: `\int_{lower}^{upper} integrand dx`
    /// - Parameters:
    ///   - lower:     The lower bound (default `"a"`).
    ///   - upper:     The upper bound (default `"b"`).
    ///   - integrand: The expression being integrated.
    ///   - variable:  The variable of integration (default `"x"`).
    static func integral(
        lower: String = "a",
        upper: String = "b",
        integrand: String,
        variable: String = "x"
    ) -> String {
        "\\int_{\(lower)}^{\(upper)} \(integrand) d\(variable)"
    }

    // MARK: - Greek Letters

    /// Returns the LaTeX command for a Greek letter: `\letter`
    /// - Parameter letter: The Greek letter name (e.g. `"alpha"`, `"beta"`).
    /// - Note: The backslash is included automatically.
    static func greek(_ letter: String) -> String {
        "\\\(letter)"
    }
}
