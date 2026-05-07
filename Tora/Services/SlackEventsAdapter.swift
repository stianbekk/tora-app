import Foundation
import OSLog

// MARK: - Slack Events API payload shapes

struct SlackEventEnvelope: Decodable, Sendable {
    let token: String?
    let team_id: String?
    let api_app_id: String?
    let type: String
    let event: SlackEvent?
    let event_id: String?
}

struct SlackEvent: Decodable, Sendable {
    let type: String
    let subtype: String?
    let user: String?
    let bot_id: String?
    let text: String?
    let channel: String?
    let channel_type: String?
    let ts: String?
}

// MARK: - Adapter

/// Receives raw Slack Events API payloads from the relay server, parses them,
/// resolves user/channel labels via the Slack Web API, and routes the result
/// to the ExtractionService.
actor SlackEventsAdapter: SlackEventsHandler {
    private let logger = Logger(subsystem: "ai.truste.Tora", category: "slack-events")

    private let api: SlackAPIClient
    private let extraction: ExtractionService
    private let seenChannels: SeenChannelStore
    private weak var stateRefresh: StateRefresher?

    /// User-supplied Slack bot token (xoxb-...).
    private var botToken: String?

    /// Cache of user/channel display names so we don't hit the Web API on every event.
    private var userCache: [String: String] = [:]
    private var channelCache: [String: String] = [:]

    /// Configurable workspace identifier — used as the suggestion source_id.
    private var sourceId: String = "slack:default"

    /// If true, messages from bots are dropped before extraction.
    var skipBotMessages: Bool = true

    init(
        api: SlackAPIClient = SlackAPIClient(),
        extraction: ExtractionService,
        seenChannels: SeenChannelStore = SeenChannelStore(),
        stateRefresh: StateRefresher? = nil
    ) {
        self.api = api
        self.extraction = extraction
        self.seenChannels = seenChannels
        self.stateRefresh = stateRefresh
    }

    func setBotToken(_ token: String?) { self.botToken = token }
    func setSourceId(_ id: String) { self.sourceId = id }
    func setStateRefresher(_ refresher: StateRefresher) { self.stateRefresh = refresher }

    // MARK: - SlackEventsHandler

    func handle(payload: Data, headers: HandlerHeaders) async throws {
        let envelope: SlackEventEnvelope
        do {
            envelope = try JSONDecoder().decode(SlackEventEnvelope.self, from: payload)
        } catch {
            logger.warning("Could not decode Slack envelope: \(error.localizedDescription, privacy: .public)")
            return
        }

        guard envelope.type == "event_callback", let event = envelope.event else {
            return
        }

        // Only message events for v0.
        guard event.type == "message", event.subtype == nil else { return }

        if skipBotMessages, event.bot_id != nil {
            return
        }

        guard let text = event.text, !text.isEmpty else { return }

        let person   = await resolveUserName(event.user)
        let channel  = await resolveChannelName(event.channel, hint: event.channel_type)

        let signal = Signal(
            sourceType: .slack,
            sourceId: sourceId,
            person: person,
            channel: channel,
            messageText: text,
            receivedAt: Date()
        )

        await extraction.enqueue(signal)

        // Record this channel + ts so backfill knows where to resume next launch.
        if let id = event.channel, let ts = event.ts {
            seenChannels.record(channelId: id, name: channel, ts: ts)
        }
    }

    // MARK: - Resolution with caching

    private func resolveUserName(_ id: String?) async -> String {
        guard let id, !id.isEmpty else { return "Unknown" }
        if let cached = userCache[id] { return cached }
        guard let token = botToken else { return id }
        do {
            let user = try await api.userInfo(userId: id, token: token)
            userCache[id] = user.displayName
            return user.displayName
        } catch {
            logger.warning("user resolution failed for \(id, privacy: .public)")
            return id
        }
    }

    private func resolveChannelName(_ id: String?, hint: String?) async -> String {
        guard let id, !id.isEmpty else { return hint == "im" ? "DM" : "channel" }
        if let cached = channelCache[id] { return cached }
        if hint == "im" { return "DM" }
        guard let token = botToken else { return id }
        do {
            let channel = try await api.channelInfo(channelId: id, token: token)
            channelCache[id] = channel.displayName
            return channel.displayName
        } catch {
            logger.warning("channel resolution failed for \(id, privacy: .public)")
            return id
        }
    }
}

// MARK: - StateRefresher protocol

/// Indirection so background actors can ask AppState (MainActor) to reload.
@MainActor
protocol StateRefresher: AnyObject, Sendable {
    func reload()
    func enqueueToast(for suggestion: Suggestion)
}

extension AppState: StateRefresher {
    func enqueueToast(for suggestion: Suggestion) {
        guard suggestion.urgency == .high else { return }
        do {
            let allCustomers = try CustomerRepository().all()
            let allProducts = try ProductRepository().all()
            self.pendingToast = SuggestionViewModel(
                suggestion,
                customers: allCustomers,
                products: allProducts
            )
        } catch {
            // Best-effort; non-fatal.
        }
    }
}
