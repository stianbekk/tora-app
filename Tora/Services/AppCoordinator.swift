import Foundation
import OSLog

/// Top-level orchestrator that owns long-lived services and wires them to AppState.
@MainActor
final class AppCoordinator {
    private let logger = Logger(subsystem: "ai.truste.Tora", category: "coordinator")

    let appState: AppState
    let notifications: NotificationService
    let extraction: ExtractionService
    let relay: RelayServer
    let slackAdapter: SlackEventsAdapter
    let backfill: SlackBackfillService
    let keychain: KeychainStore

    init() {
        let appState = AppState()
        let extraction = ExtractionService()
        self.appState = appState
        self.notifications = NotificationService()
        self.keychain = KeychainStore()
        self.extraction = extraction
        self.relay = RelayServer()
        self.slackAdapter = SlackEventsAdapter(extraction: extraction)
        self.backfill = SlackBackfillService(
            extraction: extraction,
            onStatusChange: { status in
                await MainActor.run {
                    appState.backfillStatus = status
                }
            }
        )
    }

    /// Bootstrap the coordinator. Called from AppDelegate.applicationDidFinishLaunching.
    func bootstrap() async {
        appState.bootstrap()
        appState.slackConnected = keychain.get(.slackBotToken) != nil
        await notifications.bootstrap()

        // Configure extraction with the persisted API key + default model.
        let apiKey = keychain.get(.openAIAPIKey)
        await extraction.configure(
            apiKey: apiKey,
            model: .defaultModel,
            batchInterval: 30
        )

        // Tell the slack adapter what its source identifier is and which token to use.
        await slackAdapter.setBotToken(keychain.get(.slackBotToken))
        await slackAdapter.setSourceId("slack:default")
        await slackAdapter.setStateRefresher(appState)
        await backfill.setSourceId("slack:default")

        // Hook the adapter into the relay server.
        await relay.setSlackHandler(slackAdapter)

        // Reload AppState + fire toast/notification when a new suggestion is persisted.
        let appState = self.appState
        let notifications = self.notifications
        await extraction.setSuggestionCreatedHandler { suggestion in
            await MainActor.run {
                appState.reload()
                appState.enqueueToast(for: suggestion)
                notifications.updateBadge(pendingCount: appState.pendingCount)
            }
            await notifications.notify(for: suggestion)
        }

        // Wire notification action callbacks back to AppState.
        notifications.onAccept = { [weak self] suggestionId in
            self?.appState.accept(suggestionId: suggestionId)
        }
        notifications.onDismiss = { [weak self] suggestionId in
            self?.appState.dismiss(suggestionId: suggestionId)
        }

        // Initial badge.
        notifications.updateBadge(pendingCount: appState.pendingCount)

        // Boot the relay server.
        do {
            try await relay.start()
        } catch {
            logger.error("Failed to start relay: \(String(describing: error), privacy: .public)")
        }

        // Catch up on messages we missed while offline.
        if let token = keychain.get(.slackBotToken), !token.isEmpty {
            Task.detached(priority: .background) { [backfill] in
                await backfill.run(token: token)
            }
        }
    }

    func shutdown() async {
        await relay.stop()
        await extraction.flushNow()
    }

    // MARK: - Configuration changes

    func updateAPIKey(_ key: String) async {
        keychain.set(.openAIAPIKey, value: key)
        await extraction.configure(
            apiKey: key,
            model: .defaultModel,
            batchInterval: 30
        )
    }

    func updateSlackToken(_ token: String) async {
        keychain.set(.slackBotToken, value: token)
        await slackAdapter.setBotToken(token)
        appState.slackConnected = !token.isEmpty

        // First time the user pastes a token, kick off backfill so the app
        // starts catching up immediately without waiting for the next launch.
        if !token.isEmpty {
            Task.detached(priority: .background) { [backfill] in
                await backfill.run(token: token)
            }
        }
    }
}
