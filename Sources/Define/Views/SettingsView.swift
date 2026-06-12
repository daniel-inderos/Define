import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    @State private var interceptShortcut = UserDefaults.standard.interceptSystemShortcut
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchAtLoginError: String?

    var body: some View {
        Form {
            Section {
                Toggle("Replace the system ⌃⌘D shortcut", isOn: $interceptShortcut)
                    .onChange(of: interceptShortcut) { _, enabled in
                        UserDefaults.standard.interceptSystemShortcut = enabled
                        appState.onHotkeyPreferenceChanged?(enabled)
                    }
                Text("When on, ⌃⌘D opens Define instead of the built-in dictionary popover. The menu bar icon always works either way.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        updateLaunchAtLogin(enabled)
                    }
                if let launchAtLoginError {
                    Text(launchAtLoginError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
                LabeledContent("Accessibility access") {
                    if appState.isAccessibilityTrusted {
                        Label("Granted", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Grant…") {
                            AccessibilityPermissionWatcher.promptForAccess()
                            AccessibilityPermissionWatcher.openSystemSettings()
                        }
                    }
                }
            }

            Section {
                LabeledContent("Version", value: Self.versionString)
                Link("Define on GitHub", destination: URL(string: "https://github.com/define-app/define")!)
            }

            Section {
                Button("Quit Define", role: .destructive) {
                    NSApp.terminate(nil)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginError = nil
        } catch {
            // Fails when running un-bundled (swift run); only works from Define.app.
            launchAtLoginError = "Couldn’t update login item: \(error.localizedDescription)"
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private static var versionString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }
}
