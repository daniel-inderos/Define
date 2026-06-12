import SwiftData
import SwiftUI

/// Every word ever looked up, most recent first, with search.
struct HistoryView: View {
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Word.lastLookedUpAt, order: .reverse) private var words: [Word]

    @State private var searchText = ""

    private var filteredWords: [Word] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return words }
        return words.filter {
            $0.term.localizedCaseInsensitiveContains(query)
                || $0.definition.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            if filteredWords.isEmpty {
                emptyState
            } else {
                List(filteredWords) { word in
                    HistoryRow(word: word)
                        .contentShape(Rectangle())
                        .onTapGesture { appState.show(word) }
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                try? appState.store.delete(word)
                            }
                        }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search \(words.count) words", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .glassFieldBackground()
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                words.isEmpty ? "No Lookups Yet" : "No Matches",
                systemImage: words.isEmpty ? "clock" : "magnifyingglass"
            )
        } description: {
            Text(
                words.isEmpty
                    ? "Every word you look up is saved here automatically."
                    : "No saved words match “\(searchText)”."
            )
        }
    }
}

struct HistoryRow: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text(word.term)
                    .font(.headline)
                Spacer()
                Text(word.lastLookedUpAt, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(word.definition)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            if !word.folderList.isEmpty {
                Text(word.folderList.map(\.name).sorted().joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
