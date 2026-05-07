import Foundation
import OSLog

// MARK: - Backfill status

enum BackfillStatus: Sendable, Equatable {
    case idle
    case running(channelsRemaining: Int)
    case done(processed: Int)
    case failed(reason: String)
}

// MARK: - Service

/// Runs `conversations.history` for each known Slack channel and feeds the
/// results into the same extraction pipeline as live events.
///
/// Why: Slack's Events API only retries failed webhooks for ~1 hour. If the
/// user's Mac is offline longer than that, messages are permanently lost.
/// Backfill closes the gap on app launch.
actor SlackBackfillService {
    private let logger = Logger(subsystem: "ai.truste.Tora", category: "slack-backfill")

    private let api: SlackAPIClient
    private let extraction: ExtractionService
    private let store: SeenChannelStore
    private let onStatusChange: @Sendable (BackfillStatus) async -> Void

    /// Set by AppCoordinator with the workspace identifier (matches the source
    /// id used by SlackEventsAdapter so live + backfill produce the same dedup
    /// hash for identical messages).
    private var sourceId: String = "slack:default"

    init(
        api: SlackAPIClient = SlackAPIClient(),
        extraction: ExtractionService,
        store: SeenChannelStore = SeenChannelStore(),
        onStatusChange: @escaping @Sendable (BackfillStatus) async -> Void = { _ in }
    ) {
        self.api = api
        self.extraction = extraction
        self.store = store
        self.onStatusChange = onStatusChange
    }

    func setSourceId(_ id: String) { self.sourceId = id }

    /// Run a one-shot backfill across all known channels. Safe to call concurrently
    /// with live events — the extraction service dedups via `signal.contentHash`,
    /// so a message that arrived via webhook AND backfill is processed only once.
    func run(token: String) async {
        let channels = store.all()
        guard !channels.isEmpty else {
            await onStatusChange(.done(processed: 0))
            return
        }

        await onStatusChange(.running(channelsRemaining: channels.count))

        var processedCount = 0
        var remaining = channels.count

        for channel in channels {
            do {
                processedCount += try await fetchAndForward(channel: channel, token: token)
            } catch {
                logger.warning("Backfill failed for \(channel.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
            remaining -= 1
            await onStatusChange(.running(channelsRemaining: remaining))
        }

        await onStatusChange(.done(processed: processedCount))
    }

    private func fetchAndForward(channel: SeenChannel, token: String) async throws -> Int {
        var cursor: String? = nil
        var total = 0
        var newestTs = channel.lastSeenTs

        repeat {
            let response = try await api.conversationsHistory(
                channelId: channel.id,
                oldest: channel.lastSeenTs,
                cursor: cursor,
                token: token
            )

            for message in response.messages ?? [] {
                guard let text = message.text, !text.isEmpty,
                      message.subtype == nil,
                      message.bot_id == nil else { continue }

                let signal = Signal(
                    sourceType: .slack,
                    sourceId: sourceId,
                    person: message.user ?? "Unknown",
                    channel: channel.name,
                    messageText: text,
                    receivedAt: parseTs(message.ts) ?? Date()
                )
                await extraction.enqueue(signal)
                total += 1

                if let ts = message.ts, compareTs(ts, newestTs) > 0 {
                    newestTs = ts
                }
            }

            cursor = response.response_metadata?.next_cursor
            if cursor?.isEmpty ?? true { cursor = nil }
        } while cursor != nil

        if newestTs != channel.lastSeenTs {
            store.setLastSeen(channelId: channel.id, ts: newestTs)
        }
        return total
    }

    private func parseTs(_ ts: String?) -> Date? {
        guard let ts, let seconds = Double(ts) else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }

    private func compareTs(_ a: String, _ b: String) -> Int {
        if a == b { return 0 }
        if let aD = Double(a), let bD = Double(b) {
            if aD > bD { return 1 }
            if aD < bD { return -1 }
            return 0
        }
        return a > b ? 1 : -1
    }
}
