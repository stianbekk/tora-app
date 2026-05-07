import Foundation
import UserNotifications
import OSLog
import AppKit

// MARK: - Per-urgency preferences

struct NotificationPreferences: Codable, Sendable, Equatable {
    var highUrgency: Bool = true   // banner + sound
    var mediumUrgency: Bool = true // silent notification
    var lowUrgency: Bool = true    // badge only

    static let `default` = NotificationPreferences()
}

// MARK: - Notification actions

enum NotificationCategory {
    static let suggestion = "tora.suggestion"
    static let acceptAction  = "tora.accept"
    static let dismissAction = "tora.dismiss"
}

// MARK: - Service

@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    private let logger = Logger(subsystem: "ai.truste.Tora", category: "notifications")
    private let center = UNUserNotificationCenter.current()

    var preferences: NotificationPreferences = .default

    /// Set by AppDelegate so accept/dismiss tap handlers can act on the database.
    var onAccept: ((_ suggestionId: String) -> Void)?
    var onDismiss: ((_ suggestionId: String) -> Void)?

    /// Latest pending count — also written to the menu bar badge.
    private(set) var pendingCount: Int = 0
    var statusItemBadgeUpdate: ((Int) -> Void)?

    func bootstrap() async {
        center.delegate = self
        registerCategories()
        await requestAuthorization()
    }

    private func registerCategories() {
        let accept = UNNotificationAction(
            identifier: NotificationCategory.acceptAction,
            title: "Accept",
            options: [.foreground]
        )
        let dismiss = UNNotificationAction(
            identifier: NotificationCategory.dismissAction,
            title: "Dismiss",
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: NotificationCategory.suggestion,
            actions: [accept, dismiss],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    private func requestAuthorization() async {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            logger.error("Notification authorization failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Notify

    /// Fire a notification appropriate for the urgency, if the user has opted in.
    func notify(for suggestion: Suggestion) async {
        switch suggestion.urgency {
        case .high:
            guard preferences.highUrgency else { return }
            await deliver(suggestion: suggestion, silent: false)
        case .medium:
            guard preferences.mediumUrgency else { return }
            await deliver(suggestion: suggestion, silent: true)
        case .low:
            // Badge-only — handled by `updateBadge`.
            return
        }
    }

    private func deliver(suggestion: Suggestion, silent: Bool) async {
        let content = UNMutableNotificationContent()
        content.title = "Tora"
        content.body = suggestion.title
        content.subtitle = [suggestion.sourcePerson, suggestion.sourceChannel]
            .compactMap { $0 }
            .joined(separator: " · ")
        content.categoryIdentifier = NotificationCategory.suggestion
        content.userInfo = ["suggestionId": suggestion.id]
        if !silent {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: "suggestion-\(suggestion.id)",
            content: content,
            trigger: nil
        )
        do {
            try await center.add(request)
        } catch {
            logger.error("Failed to deliver notification: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Badge management

    func updateBadge(pendingCount: Int) {
        self.pendingCount = pendingCount
        statusItemBadgeUpdate?(pendingCount)
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let actionId = response.actionIdentifier
        guard let suggestionId = userInfo["suggestionId"] as? String else { return }

        await MainActor.run {
            switch actionId {
            case NotificationCategory.acceptAction:
                self.onAccept?(suggestionId)
            case NotificationCategory.dismissAction:
                self.onDismiss?(suggestionId)
            default:
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
