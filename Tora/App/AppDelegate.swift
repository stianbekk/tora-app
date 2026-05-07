import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var taskListWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var firstRunWindow: NSWindow?
    private var toastWindow: NSWindow?

    private let coordinator = AppCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        Task { @MainActor in
            await coordinator.bootstrap()
            updateBadge(count: coordinator.appState.pendingCount)
            startToastWatcher()
        }
        coordinator.notifications.statusItemBadgeUpdate = { [weak self] count in
            Task { @MainActor [weak self] in self?.updateBadge(count: count) }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        let coord = coordinator
        Task { await coord.shutdown() }
    }

    // MARK: - Status item

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(named: "Mascot")
            button.image?.size = NSSize(width: 18, height: 18)
            button.image?.isTemplate = false
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        statusItem = item
    }

    private func updateBadge(count: Int) {
        guard let button = statusItem?.button else { return }
        button.title = count > 0 ? " \(count)" : ""
    }

    // MARK: - Popover

    private func setupPopover() {
        let pop = NSPopover()
        pop.contentSize = NSSize(width: 380, height: 420)
        pop.behavior = .transient

        let root = PopoverView(
            onOpenTaskList: { [weak self] filter in
                self?.openTaskList(initialFilter: filter)
            },
            onOpenSettings: { [weak self] in
                self?.openSettings()
            }
        )
        .environment(coordinator.appState)
        .environment(\.toraAccent, coordinator.appState.accent.color)

        pop.contentViewController = NSHostingController(rootView: root)
        popover = pop
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Refresh state when popover opens — cheap because tables are small.
            coordinator.appState.reload()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Detached windows

    private func openTaskList(initialFilter: SidebarFilter) {
        coordinator.appState.sidebarFilter = initialFilter
        coordinator.appState.reload()
        if let window = taskListWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = TaskListView()
            .environment(coordinator.appState)
            .environment(\.toraAccent, coordinator.appState.accent.color)

        let controller = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: controller)
        window.title = "Tora — Tasks"
        window.setContentSize(NSSize(width: 780, height: 540))
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        taskListWindow = window
    }

    private func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView(coordinator: coordinator)
            .environment(coordinator.appState)
            .environment(\.toraAccent, coordinator.appState.accent.color)

        let controller = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: controller)
        window.title = "Tora — Settings"
        window.setContentSize(NSSize(width: 760, height: 520))
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    // MARK: - Toast

    private func startToastWatcher() {
        // Poll every second for queued toasts. Wave 5 will replace this with a proper observation.
        Task { @MainActor [weak self] in
            while true {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self else { return }
                if let toast = self.coordinator.appState.pendingToast {
                    self.coordinator.appState.pendingToast = nil
                    self.showToast(toast)
                }
            }
        }
    }

    private func showToast(_ suggestion: SuggestionViewModel) {
        toastWindow?.close()

        let view = NotificationToastView(
            suggestion: suggestion,
            onAccept: { [weak self] in
                self?.coordinator.appState.accept(suggestionId: suggestion.id)
                self?.dismissToast()
            },
            onDismiss: { [weak self] in
                self?.coordinator.appState.dismiss(suggestionId: suggestion.id)
                self?.dismissToast()
            },
            onClose: { [weak self] in self?.dismissToast() }
        )
        .environment(\.toraAccent, coordinator.appState.accent.color)

        let controller = NSHostingController(rootView: view)
        let window = NSPanel(
            contentViewController: controller
        )
        window.styleMask = [.borderless, .nonactivatingPanel]
        window.isFloatingPanel = true
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.setContentSize(NSSize(width: 380, height: 200))
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            window.setFrameOrigin(NSPoint(x: frame.maxX - 380 - 14, y: frame.maxY - 220))
        }
        window.orderFrontRegardless()
        toastWindow = window

        // Auto-dismiss after 8 seconds if the user doesn't act.
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            self?.dismissToast()
        }
    }

    private func dismissToast() {
        toastWindow?.close()
        toastWindow = nil
    }

    // MARK: - First run

    func openFirstRun() {
        if let window = firstRunWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }
        let view = FirstRunView(onDone: { [weak self] in
            self?.firstRunWindow?.close()
            self?.firstRunWindow = nil
        })
        .environment(coordinator.appState)
        .environment(\.toraAccent, coordinator.appState.accent.color)

        let controller = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: controller)
        window.title = "Set up Tora"
        window.setContentSize(NSSize(width: 720, height: 560))
        window.styleMask = [.titled, .closable, .resizable]
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        firstRunWindow = window
    }
}
