import XCTest
@testable import Tora

final class RelayServerTests: XCTestCase {
    func test_slackChallenge_extractsChallenge() {
        let payload = #"{"type":"url_verification","challenge":"abc123","token":"x"}"#
        let challenge = SlackChallenge.extract(from: Data(payload.utf8))
        XCTAssertEqual(challenge, "abc123")
    }

    func test_slackChallenge_returnsNilForMessageEvents() {
        let payload = #"{"type":"event_callback","event":{}}"#
        XCTAssertNil(SlackChallenge.extract(from: Data(payload.utf8)))
    }

    func test_slackSignature_validatesCorrectly() {
        // Reference vector: timestamp=1531420618, body=request body
        let secret = "8f742231b10e8888abcd99yyyzzz85a5"
        let timestamp = "1531420618"
        let body = Data("token=xyzz0WbapA4vBCDEFasx0q6G&team_id=T1DC2JH3J".utf8)
        // Compute expected signature once, then verify constant-time check accepts it.
        let expected = "v0=" + HMAC.sha256(
            key: secret,
            message: "v0:\(timestamp):\(String(data: body, encoding: .utf8)!)"
        )
        XCTAssertTrue(SlackSignatureVerifier.verify(
            signature: expected,
            timestamp: timestamp,
            body: body,
            signingSecret: secret
        ))
    }

    func test_slackSignature_rejectsTampered() {
        let secret = "test-secret"
        let body = Data("hello".utf8)
        XCTAssertFalse(SlackSignatureVerifier.verify(
            signature: "v0=deadbeef",
            timestamp: "1700000000",
            body: body,
            signingSecret: secret
        ))
    }
}
