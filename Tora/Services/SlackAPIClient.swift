import Foundation

// MARK: - Slack Web API client (read-only paths used by Tora)

enum SlackAPIError: Error {
    case http(status: Int, body: String)
    case slack(error: String)
    case decoding(Error)
}

/// Minimal Slack Web API client. Used to resolve user IDs to display names
/// and channel IDs to readable labels.
struct SlackAPIClient: Sendable {
    var baseURL: URL = URL(string: "https://slack.com/api")!
    var session: URLSessionProtocol = URLSession.shared

    func userInfo(userId: String, token: String) async throws -> SlackUser {
        let url = baseURL.appendingPathComponent("users.info")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "user", value: userId)]
        return try await get(url: components.url!, token: token, decoding: SlackUserInfoResponse.self).user
    }

    func channelInfo(channelId: String, token: String) async throws -> SlackChannel {
        let url = baseURL.appendingPathComponent("conversations.info")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "channel", value: channelId)]
        return try await get(url: components.url!, token: token, decoding: SlackChannelInfoResponse.self).channel
    }

    /// Pull a page of messages from a channel newer than `oldest` (Slack-format timestamp).
    /// `cursor` advances through paginated results — pass nil for the first page,
    /// then re-call with the returned `next_cursor` until it's nil.
    func conversationsHistory(
        channelId: String,
        oldest: String?,
        cursor: String?,
        limit: Int = 200,
        token: String
    ) async throws -> SlackHistoryResponse {
        let url = baseURL.appendingPathComponent("conversations.history")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        var items = [
            URLQueryItem(name: "channel", value: channelId),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        if let oldest, !oldest.isEmpty {
            items.append(URLQueryItem(name: "oldest", value: oldest))
        }
        if let cursor, !cursor.isEmpty {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }
        components.queryItems = items
        return try await get(url: components.url!, token: token, decoding: SlackHistoryResponse.self)
    }

    private func get<T: Decodable & Sendable>(
        url: URL, token: String, decoding: T.Type
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SlackAPIError.http(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw SlackAPIError.decoding(error)
        }
    }
}

// MARK: - Response types

struct SlackUserInfoResponse: Decodable, Sendable {
    let ok: Bool
    let user: SlackUser
}

struct SlackChannelInfoResponse: Decodable, Sendable {
    let ok: Bool
    let channel: SlackChannel
}

struct SlackUser: Decodable, Sendable, Hashable {
    let id: String
    let name: String?
    let real_name: String?
    let is_bot: Bool?

    var displayName: String { real_name ?? name ?? id }
}

struct SlackChannel: Decodable, Sendable, Hashable {
    let id: String
    let name: String?
    let is_im: Bool?
    let is_group: Bool?

    var displayName: String {
        if is_im == true { return "DM" }
        if let n = name { return "#\(n)" }
        return id
    }
}

// MARK: - History response

struct SlackHistoryResponse: Decodable, Sendable {
    let ok: Bool
    let messages: [SlackHistoryMessage]?
    let has_more: Bool?
    let response_metadata: SlackResponseMetadata?
}

struct SlackHistoryMessage: Decodable, Sendable {
    let type: String?
    let subtype: String?
    let user: String?
    let bot_id: String?
    let text: String?
    let ts: String?
    let thread_ts: String?
}

struct SlackResponseMetadata: Decodable, Sendable {
    let next_cursor: String?
}
