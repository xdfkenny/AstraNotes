// ObsidianService.swift — AstraNotes
// Manages Obsidian vault integration for AstraNotes.
// Handles vault selection/validation, folder hierarchy creation by IB subject,
// YAML frontmatter generation, wikilink parsing, tag management, and resource management.

import Foundation
#if os(macOS)
import AppKit
#endif
import SwiftUI

// MARK: - Obsidian Service

@Observable
final class ObsidianService {

    // MARK: - Published State

    var vaultPath: String = ""
    var isVaultValid: Bool = false
    var vaultStructure: [VaultFolder] = []
    var lastError: String?

    // MARK: - Persistence

    private let vaultPathKey = "obsidianVaultPath"

    // MARK: - Initialization

    init() {
        if let savedPath = UserDefaults.standard.string(forKey: vaultPathKey) {
            vaultPath = savedPath
            validateVault()
        }
    }

    // MARK: - Vault Selection

    /// Presents an NSOpenPanel for the user to select their Obsidian vault root.
    func selectVault() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.title = "Select Obsidian Vault"
        panel.prompt = "Select Vault"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = false
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser

        if panel.runModal() == .OK, let url = panel.url {
            vaultPath = url.path
            UserDefaults.standard.set(vaultPath, forKey: vaultPathKey)
            validateVault()
        }
        #else
        // On iOS, vault selection is handled via .fileImporter in SwiftUI views
        // due to sandbox restrictions. See SettingsView for the fileImporter modifier.
        #endif
    }

    // MARK: - Validation

    /// Validates that the selected path contains a `.obsidian` configuration folder.
    func validateVault() {
        let fm = FileManager.default
        let obsidianFolder = (vaultPath as NSString).appendingPathComponent(".obsidian")
        isVaultValid = fm.fileExists(atPath: obsidianFolder)

        if !isVaultValid && !vaultPath.isEmpty {
            lastError = String(localized: "error.noObsidianFolder")
        } else {
            lastError = nil
        }

        scanVaultStructure()
    }

    // MARK: - Vault Structure Scanning

    /// Recursively scans the vault to discover all folders (excluding hidden ones).
    func scanVaultStructure() {
        guard !vaultPath.isEmpty else {
            vaultStructure = []
            return
        }

        let fm = FileManager.default
        let vaultURL = URL(fileURLWithPath: vaultPath)

        var folders: [VaultFolder] = []

        if let enumerator = fm.enumerator(
            at: vaultURL,
            includingPropertiesForKeys: [.isDirectoryKey, .localizedNameKey],
            options: [.skipsHiddenFiles]
        ) {
            while let fileURL = enumerator.nextObject() as? URL {
                let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey])
                if resourceValues?.isDirectory == true {
                    let relativePath = fileURL.path
                        .replacingOccurrences(of: vaultPath, with: "")
                        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

                    // Skip the .obsidian config folder itself
                    guard !relativePath.hasPrefix(".obsidian") else { continue }

                    folders.append(VaultFolder(
                        name: fileURL.lastPathComponent,
                        path: relativePath,
                        url: fileURL
                    ))
                }
            }
        }

        // Sort folders alphabetically by relative path
        folders.sort { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
        vaultStructure = folders
    }

    // MARK: - Note Saving

    /// Saves a note to the vault, creating the subject folder hierarchy automatically.
    /// Folder structure: `IB/{Subject} {Level}/{YYYY-MM}/`
    /// File naming: `{YYYY-MM-DD}_{Lecture-Topic}.md`
    ///
    /// - Returns: The file URL of the saved note, or `nil` on failure.
    @discardableResult
    func saveNote(
        title: String,
        content: String,
        subject: String,
        level: String,
        group: Int,
        teacher: String,
        tags: [String],
        duration: String,
        relatedNotes: [String] = [],
        customFrontmatter: [String: String] = [:]
    ) -> URL? {
        guard isVaultValid else {
            lastError = String(localized: "error.noVaultSelected")
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())
        formatter.dateFormat = "yyyy-MM"
        let monthStr = formatter.string(from: Date())

        // Create folder hierarchy: IB/Subject Level/YYYY-MM/
        let folderPath = "IB/\(subject) \(level)/\(monthStr)"
        let fullFolderPath = (vaultPath as NSString).appendingPathComponent(folderPath)

        let fm = FileManager.default
        do {
            try fm.createDirectory(atPath: fullFolderPath, withIntermediateDirectories: true)
        } catch {
            lastError = String(format: String(localized: "error.obsidianCreateFolderDetail"), error.localizedDescription)
            return nil
        }

        // Sanitize title for filename
        let safeTitle = sanitizeForFilename(title)
        let fileName = "\(dateStr)_\(safeTitle).md"
        let filePath = (fullFolderPath as NSString).appendingPathComponent(fileName)

        // Generate YAML frontmatter
        let frontmatter = generateFrontmatter(
            title: title,
            subject: "\(subject) \(level)",
            group: group,
            date: dateStr,
            tags: tags,
            type: "lecture-notes",
            teacher: teacher,
            duration: duration,
            related: relatedNotes,
            custom: customFrontmatter
        )

        // Combine frontmatter + content + footer
        let fullContent = frontmatter + "\n\n" + content + "\n\n---\n*Generated by AstraNotes \\· \(dateStr)*\n"

        do {
            try fullContent.write(toFile: filePath, atomically: true, encoding: .utf8)
            lastError = nil
            scanVaultStructure()
            return URL(fileURLWithPath: filePath)
        } catch {
            lastError = String(format: String(localized: "error.obsidianWriteNoteDetail"), error.localizedDescription)
            return nil
        }
    }

    // MARK: - Frontmatter Generation

    /// Generates YAML frontmatter for an Obsidian-compatible markdown note.
    func generateFrontmatter(
        title: String,
        subject: String,
        group: Int,
        date: String,
        tags: [String],
        type: String,
        teacher: String,
        duration: String,
        related: [String],
        custom: [String: String]
    ) -> String {
        var lines = ["---"]
        lines.append("title: \"\(escapeYAML(title))\"")
        lines.append("subject: \"\(escapeYAML(subject))\"")
        lines.append("group: \(group)")
        lines.append("date: \(date)")

        if !tags.isEmpty {
            let tagString = tags.map { "\"\($0)\"" }.joined(separator: ", ")
            lines.append("tags: [\(tagString)]")
        }

        lines.append("type: \(type)")
        lines.append("teacher: \"\(escapeYAML(teacher))\"")
        lines.append("duration: \"\(escapeYAML(duration))\"")
        lines.append("status: reviewed")

        if !related.isEmpty {
            let relatedString = related.map { "[[\(escapeYAML($0))]]" }.joined(separator: ", ")
            lines.append("related: \(relatedString)")
        }

        // Append any custom frontmatter fields
        for (key, value) in custom {
            lines.append("\(key): \(value)")
        }

        lines.append("---")
        return lines.joined(separator: "\n")
    }

    // MARK: - Wikilink Parsing

    /// Parses a markdown string and extracts all `[[wikilinks]]`.
    func parseWikilinks(from markdown: String) -> [String] {
        let pattern = #"\[\[([^\]]+)\]\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let range = NSRange(markdown.startIndex..., in: markdown)
        let matches = regex.matches(in: markdown, options: [], range: range)

        return matches.compactMap { match in
            let linkRange = Range(match.range(at: 1), in: markdown)
            return linkRange.map { String(markdown[$0]) }
        }
    }

    /// Converts `[[wikilinks]]` in markdown into Obsidian-compatible HTML anchor tags.
    func renderWikilinks(in markdown: String) -> String {
        let pattern = #"\[\[([^\]|]+)(?:\|([^\]]+))?\]\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return markdown
        }

        let nsString = markdown as NSString
        let range = NSRange(location: 0, length: nsString.length)
        let matches = regex.matches(in: markdown, options: [], range: range)

        var result = markdown
        // Process matches in reverse to preserve range offsets
        for match in matches.reversed() {
            let fullRange = match.range
            let linkRange = Range(match.range(at: 1), in: markdown)!
            let linkTarget = String(markdown[linkRange])

            let displayText: String
            if match.numberOfRanges > 2, let aliasRange = Range(match.range(at: 2), in: markdown) {
                displayText = String(markdown[aliasRange])
            } else {
                displayText = linkTarget
            }

            let replacement = "[\(displayText)](\(linkTarget).md)"
            let nsReplacement = replacement as NSString
            result = (result as NSString).replacingCharacters(in: fullRange, with: nsReplacement as String)
        }

        return result
    }

    // MARK: - Tag Management

    /// Extracts all `#tags` from a markdown string.
    func parseTags(from markdown: String) -> [String] {
        let pattern = #"(?<=\s|^)#([a-zA-Z0-9_\-/]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let range = NSRange(markdown.startIndex..., in: markdown)
        let matches = regex.matches(in: markdown, options: [], range: range)

        return matches.compactMap { match in
            let tagRange = Range(match.range(at: 1), in: markdown)
            return tagRange.map { String(markdown[$0]) }
        }
    }

    /// Returns the unique set of tags used across all markdown files in the vault.
    func collectAllVaultTags() -> Set<String> {
        guard isVaultValid else { return [] }
        let fm = FileManager.default
        let vaultURL = URL(fileURLWithPath: vaultPath)
        var allTags: Set<String> = []

        if let enumerator = fm.enumerator(
            at: vaultURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            while let fileURL = enumerator.nextObject() as? URL {
                guard fileURL.pathExtension == "md" else { continue }
                if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                    let tags = parseTags(from: content)
                    allTags.formUnion(tags)
                }
            }
        }

        return allTags
    }

    // MARK: - Resource Management

    /// Copies a resource file into the vault's attachments folder.
    /// - Returns: The relative path within the vault for the copied resource.
    @discardableResult
    func copyResource(at sourceURL: URL, to subfolder: String = "attachments") -> String? {
        guard isVaultValid else { return nil }

        let fm = FileManager.default
        let attachmentsPath = (vaultPath as NSString).appendingPathComponent(subfolder)

        do {
            try fm.createDirectory(atPath: attachmentsPath, withIntermediateDirectories: true)
        } catch {
            lastError = String(format: String(localized: "error.obsidianCreateAttachmentsFolder"), error.localizedDescription)
            return nil
        }

        let destinationURL = URL(fileURLWithPath: attachmentsPath)
            .appendingPathComponent(sourceURL.lastPathComponent)

        // Handle filename collisions by appending a counter
        var finalURL = destinationURL
        var counter = 1
        while fm.fileExists(atPath: finalURL.path) {
            let name = sourceURL.deletingPathExtension().lastPathComponent
            let ext = sourceURL.pathExtension
            finalURL = URL(fileURLWithPath: attachmentsPath)
                .appendingPathComponent("\(name)_\(counter).\(ext)")
            counter += 1
        }

        do {
            try fm.copyItem(at: sourceURL, to: finalURL)
            let relativePath = (subfolder as NSString).appendingPathComponent(finalURL.lastPathComponent)
            lastError = nil
            return relativePath
        } catch {
            lastError = String(format: String(localized: "error.obsidianCopyResource"), error.localizedDescription)
            return nil
        }
    }

    // MARK: - Helpers

    /// Sanitizes a string for use as a filename component.
    private func sanitizeForFilename(_ string: String) -> String {
        string
            .replacingOccurrences(of: ":", with: " -")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: "*", with: "-")
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "|", with: "-")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Escapes basic YAML-special characters within a string value.
    private func escapeYAML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
    }

    /// Deletes a note file from the vault at the given relative path.
    func deleteNote(at relativePath: String) -> Bool {
        let fm = FileManager.default
        let fullPath = (vaultPath as NSString).appendingPathComponent(relativePath)

        guard fm.fileExists(atPath: fullPath) else { return false }

        do {
            try fm.removeItem(atPath: fullPath)
            scanVaultStructure()
            return true
        } catch {
            lastError = String(format: String(localized: "error.obsidianDeleteNoteDetail"), error.localizedDescription)
            return false
        }
    }

    /// Moves a note to a new location within the vault.
    func moveNote(from oldRelativePath: String, to newRelativePath: String) -> Bool {
        let fm = FileManager.default
        let oldFullPath = (vaultPath as NSString).appendingPathComponent(oldRelativePath)
        let newFullPath = (vaultPath as NSString).appendingPathComponent(newRelativePath)

        guard fm.fileExists(atPath: oldFullPath) else { return false }

        // Ensure the destination directory exists
        let destinationDir = (newFullPath as NSString).deletingLastPathComponent
        try? fm.createDirectory(atPath: destinationDir, withIntermediateDirectories: true)

        do {
            try fm.moveItem(atPath: oldFullPath, toPath: newFullPath)
            scanVaultStructure()
            return true
        } catch {
            lastError = String(format: String(localized: "error.obsidianMoveNote"), error.localizedDescription)
            return false
        }
    }
}

// MARK: - Vault Folder Model

struct VaultFolder: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let url: URL

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    static func == (lhs: VaultFolder, rhs: VaultFolder) -> Bool {
        lhs.url == rhs.url
    }
}
