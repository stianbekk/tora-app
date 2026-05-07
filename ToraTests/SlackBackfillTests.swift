import XCTest
import GRDB
@testable import Tora

private struct StubSession: URLSessionProtocol {
    let responses: [(Data, URLResponse)]
    let counter: Counter

    final class Counter: @unchecked Sendable {
        var value = 0
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let i = counter.value
        counter.value += 1
        return responses[min(i, responses.count - 1)]
    }
}

private func makeResponse(_ json: String, status: Int = 200) -> (Data, URLResponse) {
    let url = URL(string: "https://slack.com/api/conversations.history")!
    let resp = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    return (Data(json.utf8), resp)
}

final class SlackBackfillTests: XCTestCase {
    func test_seenChannelStore_recordAndRetrieve() throws {
        let queue = try DatabaseQueue()
        try Migrator.shared.migrate(queue)
        let settings = SettingsRepository(dbQueue: queue)
        let store = SeenChannelStore(settings: settings)

        XCTAssertTrue(store.all().isEmpty)

        store.record(channelId: "C1", name: "#general", ts: "1700000000.000100")
        XCTAssertEqual(store.all().count, 1)
        XCTAssertEqual(store.all().first?.name, "#general")

        // Older ts should NOT overwrite a newer one already on file.
        store.record(channelId: "C1", name: "#general", ts: "1600000000.000100")
        XCTAssertEqual(store.all().first?.lastSeenTs, "1700000000.000100")

        // Newer ts should advance.
        store.record(channelId: "C1", name: "#general", ts: "1800000000.000100")
        XCTAssertEqual(store.all().first?.lastSeenTs, "1800000000.000100")
    }

    func test_backfillService_paginatesAndForwardsToExtraction() async throws {
        let queue = try DatabaseQueue()
        try Migrator.shared.migrate(queue)
        let settings = SettingsRepository(dbQueue: queue)
        let store = SeenChannelStore(settings: settings)

        // Seed: we've seen #general before
        store.record(channelId: "C1", name: "#general", ts: "1700000000.000000")

        // Two-page response: first page has next_cursor, second doesn't
        let page1 = """
        {
          "ok": true,
          "messages": [
            {"type":"message","user":"U1","text":"first","ts":"1700000100.000000"},
            {"type":"message","user":"U2","text":"second","ts":"1700000200.000000"}
          ],
          "has_more": true,
          "response_metadata": {"next_cursor": "abc"}
        }
        """
        let page2 = """
        {
          "ok": true,
          "messages": [
            {"type":"message","user":"U3","text":"third","ts":"1700000300.000000"}
          ],
          "has_more": false
        }
        """
        let session = StubSession(
            responses: [makeResponse(page1), makeResponse(page2)],
            counter: StubSession.Counter()
        )
        let api = SlackAPIClient(session: session)

        let extraction = ExtractionService(
            client: OpenAIClient(),
            suggestions: SuggestionRepository(dbQueue: queue),
            customers: CustomerRepository(dbQueue: queue),
            products: ProductRepository(dbQueue: queue)
        )
        // No API key → extraction will skip the OpenAI call but still buffer the signals.
        await extraction.configure(apiKey: nil, model: .defaultModel, batchInterval: 0.1)

        let backfill = SlackBackfillService(
            api: api,
            extraction: extraction,
            store: store
        )
        await backfill.setSourceId("test:slack")

        await backfill.run(token: "xoxb-test")
        await extraction.flushNow()

        // After backfill, last_seen should advance to the newest message's ts.
        let updated = store.all().first
        XCTAssertEqual(updated?.lastSeenTs, "1700000300.000000")
    }

    func test_backfillService_skipsBotsAndSubtypes() async throws {
        let queue = try DatabaseQueue()
        try Migrator.shared.migrate(queue)
        let settings = SettingsRepository(dbQueue: queue)
        let store = SeenChannelStore(settings: settings)
        store.record(channelId: "C1", name: "#general", ts: "1700000000.000000")

        let json = """
        {
          "ok": true,
          "messages": [
            {"type":"message","user":"U1","bot_id":"B1","text":"bot","ts":"1700000100.000000"},
            {"type":"message","subtype":"channel_join","user":"U2","text":"joined","ts":"1700000200.000000"},
            {"type":"message","user":"U3","text":"real","ts":"1700000300.000000"}
          ]
        }
        """
        let session = StubSession(
            responses: [makeResponse(json)],
            counter: StubSession.Counter()
        )
        let api = SlackAPIClient(session: session)
        let extraction = ExtractionService(
            client: OpenAIClient(),
            suggestions: SuggestionRepository(dbQueue: queue),
            customers: CustomerRepository(dbQueue: queue),
            products: ProductRepository(dbQueue: queue)
        )
        await extraction.configure(apiKey: nil, model: .defaultModel, batchInterval: 0.1)

        let backfill = SlackBackfillService(
            api: api,
            extraction: extraction,
            store: store
        )
        await backfill.run(token: "xoxb-test")

        // newest_ts still advances based on the last message in the response,
        // even if it was filtered out before extraction enqueue.
        XCTAssertEqual(store.all().first?.lastSeenTs, "1700000300.000000")
    }

    func test_backfillService_emptyChannels_completesQuickly() async throws {
        let queue = try DatabaseQueue()
        try Migrator.shared.migrate(queue)

        let extraction = ExtractionService(
            client: OpenAIClient(),
            suggestions: SuggestionRepository(dbQueue: queue),
            customers: CustomerRepository(dbQueue: queue),
            products: ProductRepository(dbQueue: queue)
        )
        await extraction.configure(apiKey: nil, model: .defaultModel, batchInterval: 0.1)

        var statuses: [BackfillStatus] = []
        let recorder = StatusRecorder()
        let backfill = SlackBackfillService(
            api: SlackAPIClient(),
            extraction: extraction,
            store: SeenChannelStore(settings: SettingsRepository(dbQueue: queue)),
            onStatusChange: { status in await recorder.append(status) }
        )

        await backfill.run(token: "xoxb-test")
        statuses = await recorder.statuses
        XCTAssertEqual(statuses, [.done(processed: 0)])
    }
}

private actor StatusRecorder {
    var statuses: [BackfillStatus] = []
    func append(_ s: BackfillStatus) { statuses.append(s) }
}
