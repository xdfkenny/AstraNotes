import Foundation

// MARK: - DeepSeekService
// OpenAI-compatible HTTP client for the DeepSeek V4 Flash API.
// Supports both non-streaming (generate) and streaming (generateStreaming) modes.
// Includes automatic retry with exponential back-off, token usage tracking,
// and rough cost estimation based on current DeepSeek pricing.

@MainActor
@Observable
class DeepSeekService {

    // MARK: - Stream State

    enum StreamState: Equatable {
        case idle
        case generating
        case completed
        case failed(error: String)

        // Explicit Equatable conformance so that `failed` cases with the
        // same error message compare equal (useful for SwiftUI diffing).
        static func == (lhs: StreamState, rhs: StreamState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle),
                 (.generating, .generating),
                 (.completed, .completed):
                return true
            case let (.failed(e1), .failed(e2)):
                return e1 == e2
            default:
                return false
            }
        }
    }

    // MARK: - Observable Properties

    var state: StreamState = .idle
    var streamedContent: String = ""
    var totalInputTokens: Int = 0
    var totalOutputTokens: Int = 0
    var errorMessage: String?

    // MARK: - Configuration

    private let baseURL = "https://api.deepseek.com/v1"
    private let maxRetries = 3
    private let timeoutInterval: TimeInterval = 120

    // MARK: - Public API

    /// Sends a non-streaming request and returns the full response text.
    func generate(
        prompt: String,
        systemPrompt: String? = nil,
        apiKey: String
    ) async throws -> String {
        let messages = buildMessages(prompt: prompt, systemPrompt: systemPrompt)
        let result = try await performRequest(messages: messages, stream: false, apiKey: apiKey)
        totalInputTokens += result.inputTokens
        totalOutputTokens += result.outputTokens
        return result.content
    }

    /// Streams the response token-by-token, updating `streamedContent` on the
    /// main actor as each chunk arrives.  The `state` property transitions
    /// through `.generating` -> `.completed` / `.failed`.
    func generateStreaming(
        prompt: String,
        systemPrompt: String? = nil,
        apiKey: String
    ) async {
        let messages = buildMessages(prompt: prompt, systemPrompt: systemPrompt)

        state = .generating
        streamedContent = ""
        errorMessage = nil

        do {
            let url = URL(string: "\(baseURL)/chat/completions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = timeoutInterval
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "model": "deepseek-chat",
                "messages": messages,
                "stream": true,
                "temperature": 0.7,
                "max_tokens": 8192
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw DeepSeekError.serverError
            }

            var accumulatedContent = ""
            var capturedInputTokens = 0
            var capturedOutputTokens = 0

            for try await line in bytes.lines {
                if line.hasPrefix("data: ") {
                    let data = String(line.dropFirst(6))
                    if data == "[DONE]" { break }

                    if let jsonData = data.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let delta = choices.first?["delta"] as? [String: Any],
                       let content = delta["content"] as? String {

                        accumulatedContent += content

                        // Track token usage when the server includes it.
                        if let usage = json["usage"] as? [String: Any] {
                            capturedInputTokens = usage["prompt_tokens"] as? Int ?? capturedInputTokens
                            capturedOutputTokens = usage["completion_tokens"] as? Int ?? capturedOutputTokens
                        }
                    }
                }
            }

            // Update @MainActor state after the async loop completes.
            self.streamedContent = accumulatedContent
            self.totalInputTokens = capturedInputTokens
            self.totalOutputTokens = capturedOutputTokens
            state = .completed
        } catch {
            state = .failed(error: error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Non-Streaming Request (with retry)

    private func performRequest(
        messages: [[String: String]],
        stream: Bool,
        apiKey: String
    ) async throws -> (content: String, inputTokens: Int, outputTokens: Int) {
        // Capture config values before entering async context to avoid
        // Swift 6 "sending self" data-race warnings at suspension points.
        let requestBaseURL = baseURL
        let requestTimeout = timeoutInterval
        let requestMaxRetries = maxRetries

        var lastError: Error?

        for attempt in 1...requestMaxRetries {
            do {
                let url = URL(string: "\(requestBaseURL)/chat/completions")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.timeoutInterval = requestTimeout
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let body: [String: Any] = [
                    "model": "deepseek-chat",
                    "messages": messages,
                    "stream": stream,
                    "temperature": 0.7,
                    "max_tokens": 8192
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw DeepSeekError.invalidResponse
                }

                switch httpResponse.statusCode {
                case 200...299:
                    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let choices = json["choices"] as? [[String: Any]],
                          let message = choices.first?["message"] as? [String: Any],
                          let content = message["content"] as? String else {
                        throw DeepSeekError.parseError
                    }

                    // Extract token usage
                    var inputTokens = 0
                    var outputTokens = 0
                    if let usage = json["usage"] as? [String: Any] {
                        inputTokens = usage["prompt_tokens"] as? Int ?? 0
                        outputTokens = usage["completion_tokens"] as? Int ?? 0
                    }

                    return (content: content, inputTokens: inputTokens, outputTokens: outputTokens)

                case 429:
                    // Rate limited -- back off and retry.
                    let delay = Double(attempt) * 2.0
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    lastError = DeepSeekError.rateLimited
                    continue

                case 500...599:
                    lastError = DeepSeekError.serverError
                    let delay = Double(attempt) * 2.0
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue

                default:
                    throw DeepSeekError.httpError(httpResponse.statusCode)
                }

            } catch let error where attempt < requestMaxRetries {
                lastError = error
                let delay = Double(attempt) * 2.0
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                continue
            }
        }

        throw lastError ?? DeepSeekError.unknownError
    }

    // MARK: - Helpers

    private func buildMessages(prompt: String, systemPrompt: String?) -> [[String: String]] {
        var messages: [[String: String]] = []

        if let systemPrompt = systemPrompt {
            messages.append(["role": "system", "content": systemPrompt])
        }

        messages.append(["role": "user", "content": prompt])

        return messages
    }

    /// Rough cost estimate based on current DeepSeek V4 Flash pricing.
    /// Input:  ~$0.14 / 1M tokens
    /// Output: ~$0.28 / 1M tokens
    var estimatedCost: Double {
        let inputCost  = Double(totalInputTokens)  * 0.00000014
        let outputCost = Double(totalOutputTokens) * 0.00000028
        return inputCost + outputCost
    }

    var totalTokens: Int {
        totalInputTokens + totalOutputTokens
    }

    /// Resets all tracking counters. Useful when starting a new session.
    func resetUsage() {
        totalInputTokens = 0
        totalOutputTokens = 0
        errorMessage = nil
        state = .idle
        streamedContent = ""
    }

    // MARK: - Error Types

    enum DeepSeekError: LocalizedError {
        case invalidResponse
        case parseError
        case serverError
        case rateLimited
        case httpError(Int)
        case unknownError

        var errorDescription: String? {
            switch self {
            case .invalidResponse: return String(localized: "error.invalidServerResponse")
            case .parseError:      return String(localized: "error.failedParseResponse")
            case .serverError:     return String(localized: "error.serverError")
            case .rateLimited:     return String(localized: "error.rateLimited")
            case .httpError(let code): return String(format: String(localized: "error.httpError"), code)
            case .unknownError:    return String(localized: "error.unknownError")
            }
        }
    }
}
