import AppKit
import ApplicationServices

/// Tracks whether the app has Accessibility access (required for both the
/// event tap and AX selection reading). macOS posts no notification when
/// the user flips the toggle in System Settings, so while access is missing
/// this polls once a second and reports the change as soon as it lands.
@MainActor
final class AccessibilityPermissionWatcher {
    private let onChange: (Bool) -> Void
    private var timer: Timer?
    private var lastKnown: Bool?

    init(onChange: @escaping (Bool) -> Void) {
        self.onChange = onChange
    }

    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Shows the system prompt directing the user to System Settings.
    static func promptForAccess() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func startWatching() {
        report(Self.isTrusted)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.report(Self.isTrusted)
            }
        }
    }

    func stopWatching() {
        timer?.invalidate()
        timer = nil
    }

    private func report(_ trusted: Bool) {
        guard trusted != lastKnown else { return }
        lastKnown = trusted
        onChange(trusted)
    }
}
