import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var taskListWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var firstRunWindow: NSWindow?

    private let appState = AppState()
    private let notifications = NotificationService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        Task { await notifications.bootstrap() }
        notifications.statusItemBadgeUpdate = { [weak self] count in
            Task { @MainActor [weak self] in self?.updateBadge(count: count) }
        }
        // Reflect initial pending count from the in-memory sample data.
        notifications.updateBadge(pendingCount: appState.pendingCount)
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
        .environment(appState)
        .environment(\.toraAccent, appState.accent.color)

        pop.contentViewController = NSHostingController(rootView: root)
        popover = pop
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Detached windows

    private func openTaskList(initialFilter: SidebarFilter) {
        appState.sidebarFilter = initialFilter
        if let window = taskListWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = TaskListView()
            .environment(appState)
            .environment(\.toraAccent, appState.accent.color)

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

        let view = SettingsView()
            .environment(appState)
            .environment(\.toraAccent, appState.accent.color)

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

    func openFirstRun() {
        if let window = firstRunWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }
        let view = FirstRunView(onDone: { [weak self] in
            self?.firstRunWindow?.close()
            self?.firstRunWindow = nil
        })
        .environment(appState)
        .environment(\.toraAccent, appState.accent.color)

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
