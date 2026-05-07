import XCTest
@testable import Tora

/// Live boot test — actually starts the server on a high port and hits /health.
/// Skipped automatically if port is unavailable.
final class RelayServerLiveTests: XCTestCase {
    func test_relayServer_healthEndpoint_returns200() async throws {
        let port = Int.random(in: 49152...65000)
        let server = RelayServer(config: RelayConfig(host: "127.0.0.1", port: port))

        do {
            try await server.start()
        } catch {
            throw XCTSkip("Relay server could not start on port \(port): \(error)")
        }

        defer { Task { await server.stop() } }

        // Give the server a moment to bind.
        try await Task.sleep(nanoseconds: 300_000_000)

        let url = URL(string: "http://127.0.0.1:\(port)/health")!
        let (data, response) = try await URLSession.shared.data(from: url)

        let http = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(http.statusCode, 200)

        let body = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(body.contains("\"status\":\"ok\""))

        await server.stop()
    }
}
