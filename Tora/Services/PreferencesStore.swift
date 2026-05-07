import Foundation

/// Reads and writes user preferences from the SQLite settings table.
/// Centralizes the keys so they don't drift across the codebase.
struct PreferencesStore: Sendable {
    enum Key: String {
        case firstRunComplete   = "first_run_complete"
        case accentPreset       = "accent_preset"
        case glyphVariant       = "glyph_variant"
        case appearanceMode     = "appearance_mode"
        case showInDock         = "show_in_dock"
        case launchAtLogin      = "launch_at_login"
        case openAIModelId      = "openai_model_id"
        case batchInterval      = "batch_interval_seconds"
        case slackSourceId      = "slack_source_id"
        case notifHighUrgency   = "notif_high_urgency"
        case notifMediumUrgency = "notif_medium_urgency"
        case notifLowUrgency    = "notif_low_urgency"
    }

    let repo: SettingsRepository

    init(repo: SettingsRepository = SettingsRepository()) {
        self.repo = repo
    }

    // MARK: - Generic

    func string(_ key: Key) -> String? {
        try? repo.get(key.rawValue)
    }

    func setString(_ key: Key, _ value: String?) {
        do {
            if let value {
                try repo.set(key.rawValue, value: value)
            } else {
                try repo.delete(key.rawValue)
            }
        } catch {
            print("PreferencesStore set failed: \(error)")
        }
    }

    func bool(_ key: Key, default defaultValue: Bool = false) -> Bool {
        guard let raw = string(key) else { return defaultValue }
        return raw == "true" || raw == "1"
    }

    func setBool(_ key: Key, _ value: Bool) {
        setString(key, value ? "true" : "false")
    }
}
