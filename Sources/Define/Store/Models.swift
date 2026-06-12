import Foundation
import SwiftData

/// A word the user has looked up, deduplicated by `term`.
/// Repeat lookups bump `lookupCount` and `lastLookedUpAt` instead of
/// creating a new row — "words you keep looking up" is the signal that
/// makes the history worth keeping.
@Model
final class Word {
    var term: String = ""
    var definition: String = ""
    var firstLookedUpAt: Date = Date.distantPast
    var lastLookedUpAt: Date = Date.distantPast
    var lookupCount: Int = 0
    var folders: [Folder]? = []

    init(term: String, definition: String, lookedUpAt: Date = .now) {
        self.term = term
        self.definition = definition
        self.firstLookedUpAt = lookedUpAt
        self.lastLookedUpAt = lookedUpAt
        self.lookupCount = 1
        self.folders = []
    }

    var folderList: [Folder] { folders ?? [] }
}

/// A user-created collection of words, e.g. "Biology" — the unit of
/// Anki export.
@Model
final class Folder {
    var name: String = ""
    var createdAt: Date = Date.distantPast

    @Relationship(deleteRule: .nullify, inverse: \Word.folders)
    var words: [Word]? = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
        self.words = []
    }

    var wordList: [Word] { words ?? [] }
}
