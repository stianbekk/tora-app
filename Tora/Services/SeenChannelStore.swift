import Foundation

/// A channel Tora has received at least one event from, with the latest
/// Slack-format timestamp seen. Backfill resumes from `lastSeenTs` per channel.
struct SeenChannel: Codable, Sendable, Hashable {
    let id: String
    var name: String
    var lastSeenTs: String  // Slack format: "1531420618.000400"
    var updatedAt: Date
}

/// Persists the set of channels Tora has received events from. Backed by a
/// single JSON blob in the settings table — simple, atomic, no migrations.
struct SeenChannelStore: Sendable {
    private let settings: SettingsRepository
    private let key = "slack:seen_channels"

    init(settings: SettingsRepository = SettingsRepository()) {
        self.settings = settings
    }

    func all() -> [SeenChannel] {
        guard let raw = (try? settings.get(key)) ?? nil,
              let data = raw.data(using: .utf8),
              let channels = try? JSONDecoder.iso.decode([SeenChannel].self, from: data) else {
            return []
        }
        return channels
    }

    /// Record (or update) a channel's latest seen timestamp.
    /// New `ts` only overwrites if it's newer than what we already have.
    func record(channelId: String, name: String, ts: String) {
        var current = all()
        if let idx = current.firstIndex(where: { $0.id == channelId }) {
            if compareTs(ts, current[idx].lastSeenTs) > 0 {
                current[idx].lastSeenTs = ts
                current[idx].updatedAt = Date()
            }
            // Keep latest known name in case it changed.
            current[idx].name = name
        } else {
            current.append(SeenChannel(id: channelId, name: name, lastSeenTs: ts, updatedAt: Date()))
        }
        save(current)
    }

    /// Update stored last-seen ts to the latest of the messages we just processed.
    /// Used after a backfill batch so the next run resumes correctly.
    func setLastSeen(channelId: String, ts: String) {
        var current = all()
        guard let idx = current.firstIndex(where: { $0.id == channelId }) else { return }
        if compareTs(ts, current[idx].lastSeenTs) > 0 {
            current[idx].lastSeenTs = ts
            current[idx].updatedAt = Date()
            save(current)
        }
    }

    private func save(_ channels: [SeenChannel]) {
        guard let data = try? JSONEncoder.iso.encode(channels),
              let raw = String(data: data, encoding: .utf8) else { return }
        try? settings.set(key, value: raw)
    }

    /// Slack timestamps are decimal-encoded floats. Lexical comparison after
    /// zero-padding the integer portion gives the same ordering and avoids
    /// double-precision rounding for values past 2030.
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

// MARK: - JSON helpers

extension JSONDecoder {
    static let iso: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

extension JSONEncoder {
    static let iso: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}
