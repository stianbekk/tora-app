import Foundation
import KeychainAccess

/// Thin wrapper around KeychainAccess for storing the OpenAI key and Slack token.
/// `Keychain` itself is thread-safe but isn't formally `Sendable`; the wrapper is
/// declared `@unchecked Sendable` so it can flow through Swift 6 concurrency.
struct KeychainStore: @unchecked Sendable {
    private let keychain: Keychain

    init(service: String = "ai.truste.Tora") {
        self.keychain = Keychain(service: service)
            .synchronizable(false)
            .accessibility(.afterFirstUnlock)
    }

    enum Key: String {
        case openAIAPIKey = "openai.api_key"
        case slackBotToken = "slack.bot_token"
        case slackSigningSecret = "slack.signing_secret"
    }

    func get(_ key: Key) -> String? {
        try? keychain.get(key.rawValue)
    }

    func set(_ key: Key, value: String?) {
        do {
            if let value, !value.isEmpty {
                try keychain.set(value, key: key.rawValue)
            } else {
                try keychain.remove(key.rawValue)
            }
        } catch {
            // Keychain failures are non-fatal — just log.
            print("Keychain write failed for \(key.rawValue): \(error)")
        }
    }
}
