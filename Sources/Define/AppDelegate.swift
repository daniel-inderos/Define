import AppKit
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appState: AppState!
    private var statusItemController: StatusItemController!
    private var hotkeyManager: HotkeyManager!
    private var permissionWatcher: AccessibilityPermissionWatcher!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let container = Self.makeModelContainer()
        let store = WordStore(modelContainer: container)
        appState = AppState(store: store)

        statusItemController = StatusItemController(appState: appState, modelContainer: container)

        hotkeyManager = HotkeyManager()
        hotkeyManager.onHotkey = { [weak self] in
            self?.statusItemController.lookUpCurrentSelectionAndShow()
        }

        // The event tap can only be created once the user grants Accessibility
        // access, so watch for the grant and (re)start the tap when it lands.
        permissionWatcher = AccessibilityPermissionWatcher { [weak self] trusted in
            guard let self else { return }
            self.appState.isAccessibilityTrusted = trusted
            if trusted {
                self.hotkeyManager.start()
            } else {
                self.hotkeyManager.stop()
            }
        }
        permissionWatcher.startWatching()

        appState.onHotkeyPreferenceChanged = { [weak self] enabled in
            guard let self, self.appState.isAccessibilityTrusted else { return }
            if enabled {
                self.hotkeyManager.start()
            } else {
                self.hotkeyManager.stop()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager?.stop()
    }

    private static func makeModelContainer() -> ModelContainer {
        do {
            let supportURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("Define", isDirectory: true)
            try FileManager.default.createDirectory(at: supportURL, withIntermediateDirectories: true)
            let storeURL = supportURL.appendingPathComponent("Define.store")
            let configuration = ModelConfiguration(url: storeURL)
            return try ModelContainer(for: Word.self, Folder.self, configurations: configuration)
        } catch {
            // A broken store on disk shouldn't make the app unlaunchable; fall
            // back to an in-memory store so lookups still work this session.
            NSLog("Define: failed to open persistent store (\(error)); falling back to in-memory storage")
            let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: Word.self, Folder.self, configurations: fallback)
            } catch {
                fatalError("Define: could not create even an in-memory model container: \(error)")
            }
        }
    }
}
