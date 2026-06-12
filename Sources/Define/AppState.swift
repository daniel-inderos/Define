import Foundation
import SwiftData
import SwiftUI

/// Observable app-wide state shared by the popover UI and the app layer.
@MainActor
final class AppState: ObservableObject {
    enum Tab: String, CaseIterable, Identifiable {
        case lookup, history, folders, settings
        var id: String { rawValue }
    }

    /// The outcome of the most recent lookup attempt, driving the Lookup tab.
    enum LookupOutcome {
        /// Nothing was selected when the user triggered Define.
        case noSelection
        /// A term was selected but no active dictionary knows it.
        case notFound(term: String)
        /// A definition was found (and recorded in history).
        case found(word: Word)
    }

    let store: WordStore

    @Published var selectedTab: Tab = .lookup
    @Published var lookupOutcome: LookupOutcome?
    @Published var isAccessibilityTrusted: Bool = false

    /// Set by the app layer; called when the Settings toggle changes so the
    /// event tap can be started/stopped immediately.
    var onHotkeyPreferenceChanged: ((Bool) -> Void)?

    init(store: WordStore) {
        self.store = store
    }

    /// Looks up raw selected text, records a hit in history, and switches
    /// the UI to show the result.
    func performLookup(rawSelection: String?) {
        selectedTab = .lookup

        guard let term = TermNormalizer.normalize(rawSelection) else {
            lookupOutcome = .noSelection
            return
        }
        guard let result = DefinitionService.lookUp(term) else {
            lookupOutcome = .notFound(term: term)
            return
        }
        do {
            let word = try store.recordLookup(term: result.term, definition: result.definition)
            lookupOutcome = .found(word: word)
        } catch {
            NSLog("Define: failed to record lookup: \(error)")
            // Storage failing shouldn't hide the definition the user asked for.
            let transient = Word(term: result.term, definition: result.definition)
            lookupOutcome = .found(word: transient)
        }
    }

    /// Re-opens a word from history in the Lookup tab.
    func show(_ word: Word) {
        lookupOutcome = .found(word: word)
        selectedTab = .lookup
    }
}
