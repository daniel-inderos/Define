import SwiftUI

/// Shown until the user grants Accessibility access, which Define needs to
/// read the selected word and intercept ⌃⌘D. The permission watcher flips
/// the UI over automatically once access is granted.
struct OnboardingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "hand.raised.circle")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Allow Accessibility Access")
                .font(.title3.bold())
            Text("Define needs Accessibility access to read the word you’ve selected and to respond to ⌃⌘D anywhere.\n\nYour selections never leave your Mac — definitions come from the built-in system dictionaries, fully offline.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Open System Settings") {
                AccessibilityPermissionWatcher.promptForAccess()
                AccessibilityPermissionWatcher.openSystemSettings()
            }
            .keyboardShortcut(.defaultAction)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
