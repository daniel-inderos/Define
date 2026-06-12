import SwiftUI

struct PopoverRootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $appState.selectedTab) {
                Image(systemName: "text.magnifyingglass").tag(AppState.Tab.lookup)
                    .help("Lookup")
                Image(systemName: "clock").tag(AppState.Tab.history)
                    .help("History")
                Image(systemName: "folder").tag(AppState.Tab.folders)
                    .help("Folders")
                Image(systemName: "gearshape").tag(AppState.Tab.settings)
                    .help("Settings")
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            Group {
                switch appState.selectedTab {
                case .lookup:
                    LookupView()
                case .history:
                    HistoryView()
                case .folders:
                    FoldersView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 380, height: 480)
    }
}
