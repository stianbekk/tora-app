import Foundation

// MARK: - Errors

enum OpenAIError: Error {
    case missingAPIKey
    case invalidResponse
    case httpError(status: Int, body: String)
    case decodingError(Error)
    case noStructuredContent
}

// MARK: - Client

/// Thin client for OpenAI Chat Completions with structured output.
/// Stateless — safe to share across calls.
struct OpenAIClient: Sendable {
    var baseURL: URL = URL(string: "https://api.openai.com/v1")!
    var session: URLSessionProtocol = URLSession.shared

    /// Sends a single message to the model and decodes the structured output.
    func extract(
        signal: Signal,
        model: String,
        apiKey: String
    ) async throws -> ExtractionResult {
        let url = baseURL.appendingPathComponent("chat/completions")

        let userText = """
        Source: \(signal.sourceType.rawValue)
        From: \(signal.person)
        Channel: \(signal.channel)
        Message:
        \(signal.messageText)
        """

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": ExtractionSchema.systemPrompt(for: signal.sourceType)],
                ["role": "user", "content": userText]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": ExtractionSchema.name,
                    "strict": true,
                    "schema": ExtractionSchema.json()
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw OpenAIError.httpError(status: http.statusCode, body: bodyText)
        }

        let envelope = try JSONDecoder().decode(ChatCompletionEnvelope.self, from: data)
        guard let raw = envelope.choices.first?.message.content else {
            throw OpenAIError.noStructuredContent
        }

        let resultData = Data(raw.utf8)
        do {
            return try JSONDecoder().decode(ExtractionResult.self, from: resultData)
        } catch {
            throw OpenAIError.decodingError(error)
        }
    }
}

// MARK: - URLSession protocol (testability)

protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - Response envelope

private struct ChatCompletionEnvelope: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String?
        }
        let message: Message
    }
    let choices: [Choice]
}
