import AppKit
import SwiftData
import SwiftUI

/// Owns the menu bar item and the popover that anchors to it.
@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
    private let appState: AppState
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var clickAwayMonitor: Any?

    init(appState: AppState, modelContainer: ModelContainer) {
        self.appState = appState

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "character.book.closed",
                accessibilityDescription: "Define"
            )
            button.toolTip = "Define — look up the selected word (⌃⌘D)"
        }

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 380, height: 480)
        popover.contentViewController = NSHostingController(
            rootView: PopoverRootView()
                .environmentObject(appState)
                .modelContainer(modelContainer)
        )

        super.init()
        popover.delegate = self

        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
    }

    /// Menu bar click: look up whatever is selected in the frontmost app.
    /// The selection must be captured *before* the popover opens and our
    /// app activates.
    @objc private func statusItemClicked() {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        lookUpCurrentSelectionAndShow()
    }

    /// Shared entry point for the hotkey and the menu bar click.
    func lookUpCurrentSelectionAndShow() {
        let selection: String?
        if AccessibilityPermissionWatcher.isTrusted {
            selection = SelectionReader.currentSelection()
        } else {
            // Without Accessibility access there is no selection to read;
            // the Lookup tab will show onboarding instead.
            selection = nil
        }
        appState.performLookup(rawSelection: selection)
        showPopover()
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        // Activate so the popover can take keyboard focus (search field,
        // folder name field) immediately.
        NSApp.activate(ignoringOtherApps: true)
        installClickAwayMonitor()
    }

    // MARK: - Click-away dismissal

    /// `.transient` alone doesn't reliably close a status item popover when
    /// the click lands in another app (we've activated ourselves to take
    /// keyboard focus). Global monitors only see events delivered to *other*
    /// apps, so this closes on any outside click without interfering with
    /// clicks inside the popover.
    private func installClickAwayMonitor() {
        guard clickAwayMonitor == nil else { return }
        clickAwayMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.popover.performClose(nil)
            }
        }
    }

    private func removeClickAwayMonitor() {
        if let clickAwayMonitor {
            NSEvent.removeMonitor(clickAwayMonitor)
        }
        clickAwayMonitor = nil
    }

    nonisolated func popoverDidClose(_ notification: Notification) {
        Task { @MainActor in
            self.removeClickAwayMonitor()
        }
    }
}
