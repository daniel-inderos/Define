import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Folder management and Anki export.
struct FoldersView: View {
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Folder.name) private var folders: [Folder]

    @State private var selectedFolder: Folder?
    @State private var isNamingNewFolder = false
    @State private var newFolderName = ""

    var body: some View {
        Group {
            if let folder = selectedFolder, folders.contains(where: { $0.persistentModelID == folder.persistentModelID }) {
                FolderDetailView(folder: folder) {
                    selectedFolder = nil
                }
            } else {
                folderList
            }
        }
        .alert("New Folder", isPresented: $isNamingNewFolder) {
            TextField("Name", text: $newFolderName)
            Button("Create") {
                let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty {
                    _ = try? appState.store.createFolder(named: name)
                }
                newFolderName = ""
            }
            Button("Cancel", role: .cancel) { newFolderName = "" }
        }
    }

    private var folderList: some View {
        VStack(spacing: 0) {
            if folders.isEmpty {
                ContentUnavailableView {
                    Label("No Folders", systemImage: "folder")
                } description: {
                    Text("Group words by topic — “Biology”, “French”, “GRE” — then export a folder straight to Anki.")
                }
            } else {
                List(folders) { folder in
                    Button {
                        selectedFolder = folder
                    } label: {
                        HStack {
                            Label(folder.name, systemImage: "folder")
                            Spacer()
                            Text("\(folder.wordList.count)")
                                .foregroundStyle(.secondary)
                                .font(.caption.monospacedDigit())
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Delete Folder", role: .destructive) {
                            try? appState.store.deleteFolder(folder)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            Divider()
            HStack {
                Button {
                    newFolderName = ""
                    isNamingNewFolder = true
                } label: {
                    Label("New Folder", systemImage: "plus")
                }
                .glassButtonStyle()
                Spacer()
            }
            .padding(10)
        }
    }
}

/// The words inside one folder, with export actions.
struct FolderDetailView: View {
    @EnvironmentObject private var appState: AppState

    let folder: Folder
    let onBack: () -> Void

    private var sortedWords: [Word] {
        folder.wordList.sorted { $0.term.localizedCaseInsensitiveCompare($1.term) == .orderedAscending }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Label("Folders", systemImage: "chevron.left")
                }
                .glassButtonStyle()
                Spacer()
                Text(folder.name)
                    .font(.headline)
                Spacer()
                exportMenu
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            Divider()

            if sortedWords.isEmpty {
                ContentUnavailableView {
                    Label("Empty Folder", systemImage: "folder")
                } description: {
                    Text("Add words from the Lookup tab using “Add to Folder”.")
                }
            } else {
                List(sortedWords) { word in
                    HistoryRow(word: word)
                        .contentShape(Rectangle())
                        .onTapGesture { appState.show(word) }
                        .contextMenu {
                            Button("Remove from Folder") {
                                try? appState.store.remove(word, from: folder)
                            }
                        }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var exportMenu: some View {
        Menu {
            Button("Export for Anki…") { exportToFile() }
            Button("Copy as TSV") { copyToClipboard() }
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
                .font(.caption)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .disabled(sortedWords.isEmpty)
        .help("Export this folder as an Anki-importable file")
    }

    private func exportToFile() {
        let panel = NSSavePanel()
        panel.title = "Export “\(folder.name)” for Anki"
        panel.nameFieldStringValue = "\(folder.name).txt"
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let tsv = AnkiExporter.tsv(for: sortedWords, deckName: folder.name)
        do {
            try tsv.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private func copyToClipboard() {
        let tsv = AnkiExporter.tsv(for: sortedWords, deckName: folder.name)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(tsv, forType: .string)
    }
}
