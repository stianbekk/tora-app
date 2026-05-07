import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var badgeCount: Int = 0
    private let notifications = NotificationService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        Task { await notifications.bootstrap() }
        notifications.statusItemBadgeUpdate = { [weak self] count in
            Task { @MainActor [weak self] in self?.updateBadge(count: count) }
        }
    }

    private func updateBadge(count: Int) {
        badgeCount = count
        guard let button = statusItem?.button else { return }
        if count > 0 {
            button.title = " \(count)"
        } else {
            button.title = ""
        }
    }

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

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 480)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PlaceholderPopoverView())
        self.popover = popover
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
}

private struct PlaceholderPopoverView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("Mascot")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
            Text("Tora")
                .font(.system(size: 16, weight: .bold))
            Text("Wave 1 scaffold — popover coming in Wave 3-A")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(width: 380, height: 200)
    }
}
