import XCTest
import GRDB
@testable import Tora

// MARK: - Mock URLSession

private struct MockSession: URLSessionProtocol {
    let response: (Data, URLResponse)
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        return response
    }
}

private func mockResponse(json: String, status: Int = 200) -> (Data, URLResponse) {
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    let resp = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    return (Data(json.utf8), resp)
}

final class ExtractionTests: XCTestCase {
    func test_signal_contentHash_isStable() {
        let s1 = Signal(
            sourceType: .slack, sourceId: "T1", person: "Frank",
            channel: "#dm", messageText: "Hello", receivedAt: Date()
        )
        let s2 = Signal(
            sourceType: .slack, sourceId: "T1", person: "Frank",
            channel: "#dm", messageText: "Hello", receivedAt: Date().addingTimeInterval(60)
        )
        XCTAssertEqual(s1.contentHash, s2.contentHash, "Hash must ignore receivedAt")
    }

    func test_extractionResult_decodesActionable() throws {
        let json = """
        {
          "is_actionable": true,
          "task": {
            "title": "Send pricing doc",
            "source_channel": "DM",
            "source_person": "Frank",
            "urgency": "high",
            "suggested_due": "2026-05-08",
            "context_snippet": "Frank needs pricing doc by Thursday",
            "customer": "Megaflis",
            "product": null
          }
        }
        """
        let result = try JSONDecoder().decode(ExtractionResult.self, from: Data(json.utf8))
        XCTAssertTrue(result.isActionable)
        XCTAssertEqual(result.task?.title, "Send pricing doc")
        XCTAssertEqual(result.task?.urgency, .high)
        XCTAssertEqual(result.task?.customer, "Megaflis")
        XCTAssertNil(result.task?.product)
    }

    func test_extractionResult_decodesNonActionable() throws {
        let json = #"{"is_actionable": false, "task": null}"#
        let result = try JSONDecoder().decode(ExtractionResult.self, from: Data(json.utf8))
        XCTAssertFalse(result.isActionable)
        XCTAssertNil(result.task)
    }

    func test_openAIClient_parsesStructuredEnvelope() async throws {
        let inner = #"{\"is_actionable\":true,\"task\":{\"title\":\"Reply to Lise\",\"source_channel\":\"Inbox\",\"source_person\":\"Lise\",\"urgency\":\"medium\",\"suggested_due\":null,\"context_snippet\":\"Onboarding call request\",\"customer\":\"VPG\",\"product\":\"Shop Assistant\"}}"#
        let envelope = """
        {
          "id": "x",
          "object": "chat.completion",
          "choices": [
            {
              "message": {"role": "assistant", "content": "\(inner)"}
            }
          ]
        }
        """
        let client = OpenAIClient(session: MockSession(response: mockResponse(json: envelope)))

        let signal = Signal(
            sourceType: .gmail, sourceId: "gmail:me", person: "Lise",
            channel: "Inbox", messageText: "Can we book onboarding?", receivedAt: Date()
        )
        let result = try await client.extract(signal: signal, model: "gpt-5.4-mini", apiKey: "sk-test")
        XCTAssertTrue(result.isActionable)
        XCTAssertEqual(result.task?.customer, "VPG")
        XCTAssertEqual(result.task?.product, "Shop Assistant")
    }

    func test_extractionService_skipsDuplicateHash() async throws {
        let queue = try DatabaseQueue()
        try Migrator.shared.migrate(queue)

        let suggestions = SuggestionRepository(dbQueue: queue)
        let customers = CustomerRepository(dbQueue: queue)
        let products = ProductRepository(dbQueue: queue)

        // Pre-populate a source so FK is satisfied.
        let sourceRepo = SourceRepository(dbQueue: queue)
        try sourceRepo.save(Source(id: "slack:T1", type: .slack, label: "Test",
                                   config: nil, active: true, createdAt: Date()))

        let signal = Signal(
            sourceType: .slack, sourceId: "slack:T1", person: "Frank",
            channel: "DM", messageText: "Send pricing doc", receivedAt: Date()
        )

        // Pre-insert a suggestion with the matching hash.
        try suggestions.save(Suggestion(
            id: "pre", sourceId: "slack:T1", title: "old",
            sourcePerson: nil, sourceChannel: nil, urgency: .low,
            suggestedDue: nil, contextSnippet: nil,
            customerId: nil, productId: nil,
            rawSignalHash: signal.contentHash, status: .pending,
            createdAt: Date(), actedAt: nil
        ))

        let svc = ExtractionService(
            client: OpenAIClient(),
            suggestions: suggestions,
            customers: customers,
            products: products
        )
        await svc.configure(apiKey: "sk-test", model: .defaultModel, batchInterval: 0.05)
        await svc.enqueue(signal)
        await svc.flushNow()

        let pending = try suggestions.pending()
        XCTAssertEqual(pending.count, 1, "Duplicate signal must not produce a second suggestion")
    }
}
