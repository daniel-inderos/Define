import Foundation
import SwiftData

/// All writes to the model layer go through this type so the rules
/// (dedupe by term, bump counters, etc.) live in one place and are testable.
@MainActor
final class WordStore {
    let modelContainer: ModelContainer
    private var context: ModelContext { modelContainer.mainContext }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    /// Records a successful lookup, returning the (new or existing) word.
    @discardableResult
    func recordLookup(term: String, definition: String, at date: Date = .now) throws -> Word {
        if let existing = try word(forTerm: term) {
            existing.lookupCount += 1
            existing.lastLookedUpAt = date
            // The active dictionary set may have changed; keep the freshest text.
            existing.definition = definition
            try context.save()
            return existing
        }
        let word = Word(term: term, definition: definition, lookedUpAt: date)
        context.insert(word)
        try context.save()
        return word
    }

    func word(forTerm term: String) throws -> Word? {
        var descriptor = FetchDescriptor<Word>(predicate: #Predicate { $0.term == term })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func delete(_ word: Word) throws {
        context.delete(word)
        try context.save()
    }

    // MARK: - Folders

    @discardableResult
    func createFolder(named name: String) throws -> Folder {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = try folder(named: trimmed) {
            return existing
        }
        let folder = Folder(name: trimmed)
        context.insert(folder)
        try context.save()
        return folder
    }

    func folder(named name: String) throws -> Folder? {
        var descriptor = FetchDescriptor<Folder>(predicate: #Predicate { $0.name == name })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func deleteFolder(_ folder: Folder) throws {
        context.delete(folder)
        try context.save()
    }

    func add(_ word: Word, to folder: Folder) throws {
        guard !word.folderList.contains(where: { $0.persistentModelID == folder.persistentModelID }) else { return }
        word.folders = word.folderList + [folder]
        try context.save()
    }

    func remove(_ word: Word, from folder: Folder) throws {
        word.folders = word.folderList.filter { $0.persistentModelID != folder.persistentModelID }
        try context.save()
    }
}
