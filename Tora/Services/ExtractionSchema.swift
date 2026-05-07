import Foundation

// MARK: - Extraction request/response types

/// A signal sent to the extraction service.
struct Signal: Sendable, Hashable {
    let sourceType: Source.Kind
    let sourceId: String
    let person: String
    let channel: String
    let messageText: String
    let receivedAt: Date

    /// Stable hash used to deduplicate suggestions.
    var contentHash: String {
        let canonical = "\(sourceType.rawValue)|\(sourceId)|\(person)|\(channel)|\(messageText)"
        return HMAC.sha256Hex(canonical)
    }
}

/// Decoded extraction result from OpenAI structured output.
struct ExtractionResult: Codable, Sendable {
    let isActionable: Bool
    let task: ExtractedTask?

    enum CodingKeys: String, CodingKey {
        case isActionable = "is_actionable"
        case task
    }
}

struct ExtractedTask: Codable, Sendable {
    let title: String
    let sourceChannel: String
    let sourcePerson: String
    let urgency: Suggestion.Urgency
    let suggestedDue: String?
    let contextSnippet: String
    let customer: String?
    let product: String?

    enum CodingKeys: String, CodingKey {
        case title
        case sourceChannel = "source_channel"
        case sourcePerson = "source_person"
        case urgency
        case suggestedDue = "suggested_due"
        case contextSnippet = "context_snippet"
        case customer
        case product
    }
}

// MARK: - JSON Schema for OpenAI structured output

enum ExtractionSchema {
    static let name = "task_extraction"

    /// JSON Schema definition matching `ExtractionResult`.
    /// Sent to OpenAI as `response_format.json_schema`. Built per-call (no shared
    /// mutable state) to satisfy Sendable in Swift 6.
    static func json() -> [String: Any] {
        return [
        "type": "object",
        "properties": [
            "is_actionable": ["type": "boolean"],
            "task": [
                "type": ["object", "null"],
                "properties": [
                    "title": [
                        "type": "string",
                        "description": "Concise task description"
                    ],
                    "source_channel": ["type": "string"],
                    "source_person": ["type": "string"],
                    "urgency": [
                        "type": "string",
                        "enum": ["low", "medium", "high"]
                    ],
                    "suggested_due": [
                        "type": ["string", "null"],
                        "description": "ISO date YYYY-MM-DD or null"
                    ],
                    "context_snippet": [
                        "type": "string",
                        "description": "1-2 sentence summary"
                    ],
                    "customer": [
                        "type": ["string", "null"],
                        "description": "Customer or company name if mentioned"
                    ],
                    "product": [
                        "type": ["string", "null"],
                        "description": "Product or project name if referenced"
                    ]
                ],
                "required": [
                    "title", "source_channel", "source_person", "urgency",
                    "suggested_due", "context_snippet", "customer", "product"
                ],
                "additionalProperties": false
            ]
        ],
        "required": ["is_actionable", "task"],
        "additionalProperties": false
        ]
    }

    /// System prompt template. Replace `{source}` with "Slack" or "Gmail".
    static let systemPrompt = """
    You are a task extraction assistant. Given a message from {source}, \
    determine if it contains an actionable task for the user.

    If actionable, extract the task details. Pay attention to:
    - Who is asking and what they need
    - Any deadlines mentioned or implied
    - Which customer or company the task relates to (if any)
    - Which product or project is referenced (if any)

    If the message is not actionable (small talk, FYI, automated notification), \
    set is_actionable to false and task to null.
    """

    static func systemPrompt(for source: Source.Kind) -> String {
        let label = source == .slack ? "Slack" : "Gmail"
        return systemPrompt.replacingOccurrences(of: "{source}", with: label)
    }
}
