import SwiftData
import SwiftUI

/// The main tab: shows the current definition, or onboarding/empty states.
struct LookupView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if !appState.isAccessibilityTrusted {
            OnboardingView()
        } else {
            switch appState.lookupOutcome {
            case .none, .noSelection:
                emptyState
            case .notFound(let term):
                notFoundState(term: term)
            case .found(let word):
                WordDetailView(word: word)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Word Selected", systemImage: "cursorarrow.and.square.on.square.dashed")
        } description: {
            Text("Select a word in any app, then press ⌃⌘D or click the Define icon in the menu bar.")
        }
    }

    private func notFoundState(term: String) -> some View {
        ContentUnavailableView {
            Label("No Definition Found", systemImage: "questionmark.circle")
        } description: {
            Text("None of your active dictionaries define “\(term)”.\nYou can enable more dictionaries in the Dictionary app’s settings.")
        }
    }
}

/// A single word with its definition and folder membership controls.
struct WordDetailView: View {
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Folder.name) private var folders: [Folder]

    let word: Word

    @State private var isNamingNewFolder = false
    @State private var newFolderName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                Text(word.definition)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            Divider()
            folderBar
        }
        .alert("New Folder", isPresented: $isNamingNewFolder) {
            TextField("Name", text: $newFolderName)
            Button("Create & Add") { createFolderAndAdd() }
            Button("Cancel", role: .cancel) { newFolderName = "" }
        } message: {
            Text("“\(word.term)” will be added to the new folder.")
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(word.term)
                .font(.title2.bold())
                .textSelection(.enabled)
            Spacer()
            if word.lookupCount > 1 {
                Text("×\(word.lookupCount)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .help("Looked up \(word.lookupCount) times")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var folderBar: some View {
        HStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(word.folderList) { folder in
                        FolderChip(name: folder.name) {
                            try? appState.store.remove(word, from: folder)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
            Menu {
                ForEach(folders) { folder in
                    let isMember = word.folderList.contains { $0.persistentModelID == folder.persistentModelID }
                    Button {
                        if isMember {
                            try? appState.store.remove(word, from: folder)
                        } else {
                            try? appState.store.add(word, to: folder)
                        }
                    } label: {
                        if isMember {
                            Label(folder.name, systemImage: "checkmark")
                        } else {
                            Text(folder.name)
                        }
                    }
                }
                if !folders.isEmpty {
                    Divider()
                }
                Button("New Folder…") {
                    newFolderName = ""
                    isNamingNewFolder = true
                }
            } label: {
                Label("Add to Folder", systemImage: "folder.badge.plus")
                    .labelStyle(.titleAndIcon)
                    .font(.caption)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func createFolderAndAdd() {
        let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if let folder = try? appState.store.createFolder(named: name) {
            try? appState.store.add(word, to: folder)
        }
        newFolderName = ""
    }
}

/// A small removable tag showing one folder the word belongs to.
struct FolderChip: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            Text(name)
                .font(.caption)
                .lineLimit(1)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 7, weight: .bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Remove from \(name)")
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.quaternary, in: Capsule())
    }
}
