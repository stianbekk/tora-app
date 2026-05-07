import Foundation
import Hummingbird
import HummingbirdCore
import Logging
import NIOCore

// MARK: - Configuration

struct RelayConfig: Sendable {
    var host: String = "127.0.0.1"
    var port: Int = 9377
    var slackSigningSecret: String? = nil
}

// MARK: - Errors

enum RelayError: Error {
    case alreadyRunning
    case portInUse(Int)
    case missingSigningSecret
}

// MARK: - Server

/// Local HTTP relay that receives webhooks from Slack and Gmail.
///
/// Lifecycle:
///   - `start()` boots the Hummingbird server on a Task.
///   - `stop()` cancels the task and waits for graceful shutdown.
actor RelayServer {
    private let logger = Logger(label: "tora.relay")
    private(set) var config: RelayConfig
    private var serverTask: Task<Void, Error>?
    private var isRunning = false

    weak var slackHandler: SlackEventsHandler?
    weak var gmailHandler: GmailPushHandler?

    init(config: RelayConfig = RelayConfig()) {
        self.config = config
    }

    func setSlackHandler(_ handler: SlackEventsHandler) {
        slackHandler = handler
    }

    func setGmailHandler(_ handler: GmailPushHandler) {
        gmailHandler = handler
    }

    func updateConfig(_ config: RelayConfig) {
        self.config = config
    }

    func start() throws {
        guard !isRunning else { throw RelayError.alreadyRunning }

        let router = Router()
        router.get("/health") { _, _ -> Response in
            let body = #"{"status":"ok","service":"tora-relay"}"#
            return Response(
                status: .ok,
                headers: [.contentType: "application/json"],
                body: .init(byteBuffer: ByteBuffer(string: body))
            )
        }

        let slackHandler = self.slackHandler
        router.post("/slack/events") { request, context -> Response in
            try await Self.handleSlackEvent(request: request, context: context, handler: slackHandler)
        }

        let gmailHandler = self.gmailHandler
        router.post("/gmail/push") { request, context -> Response in
            try await Self.handleGmailPush(request: request, context: context, handler: gmailHandler)
        }

        let app = Application(
            router: router,
            configuration: .init(
                address: .hostname(config.host, port: config.port),
                serverName: "tora-relay"
            ),
            logger: logger
        )

        let task = Task {
            try await app.runService()
        }
        serverTask = task
        isRunning = true
        logger.info("Relay server started on \(config.host):\(config.port)")
    }

    func stop() async {
        guard isRunning, let task = serverTask else { return }
        task.cancel()
        _ = try? await task.value
        serverTask = nil
        isRunning = false
        logger.info("Relay server stopped")
    }

    // MARK: - Handlers

    private static func handleSlackEvent(
        request: Request,
        context: some RequestContext,
        handler: SlackEventsHandler?
    ) async throws -> Response {
        let body = try await request.body.collect(upTo: 1_000_000)
        let bytes = body.getBytes(at: 0, length: body.readableBytes) ?? []
        let data = Data(bytes)

        // url_verification challenge — Slack sends this when Events API URL is set.
        if let challenge = SlackChallenge.extract(from: data) {
            return Response(
                status: .ok,
                headers: [.contentType: "application/json"],
                body: .init(byteBuffer: ByteBuffer(string: #"{"challenge":"\#(challenge)"}"#))
            )
        }

        if let handler {
            try await handler.handle(payload: data, headers: request.headers)
        }
        return Response(status: .ok)
    }

    private static func handleGmailPush(
        request: Request,
        context: some RequestContext,
        handler: GmailPushHandler?
    ) async throws -> Response {
        let body = try await request.body.collect(upTo: 1_000_000)
        let bytes = body.getBytes(at: 0, length: body.readableBytes) ?? []
        let data = Data(bytes)
        if let handler {
            try await handler.handle(payload: data, headers: request.headers)
        }
        return Response(status: .ok)
    }
}

// MARK: - Slack url_verification challenge parser

enum SlackChallenge {
    static func extract(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        guard json["type"] as? String == "url_verification" else { return nil }
        return json["challenge"] as? String
    }
}

// MARK: - Slack signature verification

enum SlackSignatureVerifier {
    /// Validates a Slack request using v0 signing.
    /// Header `X-Slack-Signature` must equal `v0=` + HMAC-SHA256 of `v0:timestamp:body`.
    /// Caller is responsible for rejecting timestamps older than 5 minutes (replay protection).
    static func verify(
        signature: String,
        timestamp: String,
        body: Data,
        signingSecret: String
    ) -> Bool {
        let basestring = "v0:\(timestamp):\(String(data: body, encoding: .utf8) ?? "")"
        let computed = HMAC.sha256(key: signingSecret, message: basestring)
        return constantTimeEquals(signature, "v0=\(computed)")
    }

    private static func constantTimeEquals(_ a: String, _ b: String) -> Bool {
        let aBytes = Array(a.utf8)
        let bBytes = Array(b.utf8)
        guard aBytes.count == bBytes.count else { return false }
        var diff: UInt8 = 0
        for i in 0..<aBytes.count {
            diff |= aBytes[i] ^ bBytes[i]
        }
        return diff == 0
    }
}

// MARK: - Slack/Gmail handler protocols

protocol SlackEventsHandler: AnyObject, Sendable {
    func handle(payload: Data, headers: HTTPFields) async throws
}

protocol GmailPushHandler: AnyObject, Sendable {
    func handle(payload: Data, headers: HTTPFields) async throws
}
