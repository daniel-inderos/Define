import SwiftUI

struct PopoverRootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            tabBar
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

    /// Floating glass tab buttons on macOS 26+, a segmented picker earlier.
    @ViewBuilder
    private var tabBar: some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: 6) {
                HStack(spacing: 6) {
                    ForEach(AppState.Tab.allCases) { tab in
                        if tab == appState.selectedTab {
                            tabButton(tab).buttonStyle(.glassProminent)
                        } else {
                            tabButton(tab).buttonStyle(.glass)
                        }
                    }
                }
            }
        } else {
            segmentedTabBar
        }
        #else
        segmentedTabBar
        #endif
    }

    private func tabButton(_ tab: AppState.Tab) -> some View {
        Button {
            appState.selectedTab = tab
        } label: {
            Image(systemName: tab.systemImage)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
        }
        .help(tab.title)
    }

    private var segmentedTabBar: some View {
        Picker("", selection: $appState.selectedTab) {
            ForEach(AppState.Tab.allCases) { tab in
                Image(systemName: tab.systemImage)
                    .tag(tab)
                    .help(tab.title)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}

extension AppState.Tab {
    var systemImage: String {
        switch self {
        case .lookup: "text.magnifyingglass"
        case .history: "clock"
        case .folders: "folder"
        case .settings: "gearshape"
        }
    }

    var title: String {
        switch self {
        case .lookup: "Lookup"
        case .history: "History"
        case .folders: "Folders"
        case .settings: "Settings"
        }
    }
}
