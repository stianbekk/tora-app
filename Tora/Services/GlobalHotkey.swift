import AppKit

// MARK: - Hotkey definition

struct Hotkey: Sendable, Hashable {
    /// Lowercase character (e.g. "t", "n", "l")
    let key: String
    let modifiersRawValue: UInt

    init(key: String, modifiers: NSEvent.ModifierFlags) {
        self.key = key
        self.modifiersRawValue = modifiers.rawValue
    }

    var modifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiersRawValue)
    }

    static let togglePopover = Hotkey(key: "t", modifiers: [.command, .shift])
}

// MARK: - Manager

/// Single owner of the global event monitor. Use `register(_:handler:)` once
/// per hotkey at app launch; the monitor lives for the app's lifetime.
@MainActor
final class GlobalHotkeyManager {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var bindings: [Hotkey: () -> Void] = [:]

    func register(_ hotkey: Hotkey, handler: @escaping () -> Void) {
        bindings[hotkey] = handler
        if globalMonitor == nil {
            installMonitors()
        }
    }

    private func installMonitors() {
        // Capture only Sendable values from the event so we don't pass NSEvent
        // across actor boundaries (it isn't Sendable).
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let payload = HotkeyPayload(
                key: (event.charactersIgnoringModifiers ?? "").lowercased(),
                modifiers: event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
            )
            Task { @MainActor [weak self] in
                self?.dispatch(payload)
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let payload = HotkeyPayload(
                key: (event.charactersIgnoringModifiers ?? "").lowercased(),
                modifiers: event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
            )
            self?.dispatch(payload)
            return event
        }
    }

    private func dispatch(_ payload: HotkeyPayload) {
        let mods = NSEvent.ModifierFlags(rawValue: payload.modifiers)
        for (hotkey, handler) in bindings {
            if hotkey.key == payload.key && mods.contains(hotkey.modifiers) {
                handler()
            }
        }
    }
}

/// Sendable snapshot of an NSEvent's hotkey-relevant fields.
private struct HotkeyPayload: Sendable {
    let key: String
    let modifiers: UInt
}
