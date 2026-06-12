import SwiftData
import XCTest
@testable import Define

@MainActor
final class WordStoreTests: XCTestCase {
    private var store: WordStore!

    override func setUp() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Word.self, Folder.self, configurations: configuration)
        store = WordStore(modelContainer: container)
    }

    func testRecordLookupCreatesWord() throws {
        let word = try store.recordLookup(term: "apple", definition: "a fruit")
        XCTAssertEqual(word.term, "apple")
        XCTAssertEqual(word.lookupCount, 1)
    }

    func testRepeatLookupBumpsCountInsteadOfDuplicating() throws {
        let first = Date(timeIntervalSince1970: 1_000)
        let second = Date(timeIntervalSince1970: 2_000)
        try store.recordLookup(term: "apple", definition: "a fruit", at: first)
        let word = try store.recordLookup(term: "apple", definition: "a fruit", at: second)

        XCTAssertEqual(word.lookupCount, 2)
        XCTAssertEqual(word.firstLookedUpAt, first)
        XCTAssertEqual(word.lastLookedUpAt, second)
        XCTAssertNil(try store.word(forTerm: "banana"))

        let allWords = try store.modelContainer.mainContext.fetch(FetchDescriptor<Word>())
        XCTAssertEqual(allWords.count, 1)
    }

    func testRepeatLookupRefreshesDefinition() throws {
        try store.recordLookup(term: "apple", definition: "old text")
        let word = try store.recordLookup(term: "apple", definition: "new text")
        XCTAssertEqual(word.definition, "new text")
    }

    func testCreateFolderIsIdempotent() throws {
        let first = try store.createFolder(named: "Biology")
        let second = try store.createFolder(named: "  Biology ")
        XCTAssertEqual(first.persistentModelID, second.persistentModelID)
    }

    func testAddAndRemoveWordFromFolder() throws {
        let word = try store.recordLookup(term: "mitosis", definition: "cell division")
        let folder = try store.createFolder(named: "Biology")

        try store.add(word, to: folder)
        XCTAssertEqual(word.folderList.count, 1)
        XCTAssertEqual(folder.wordList.count, 1)

        // Adding twice is a no-op.
        try store.add(word, to: folder)
        XCTAssertEqual(word.folderList.count, 1)

        try store.remove(word, from: folder)
        XCTAssertTrue(word.folderList.isEmpty)
        XCTAssertTrue(folder.wordList.isEmpty)
    }

    func testWordCanLiveInMultipleFolders() throws {
        let word = try store.recordLookup(term: "osmosis", definition: "diffusion of water")
        let bio = try store.createFolder(named: "Biology")
        let chem = try store.createFolder(named: "Chemistry")

        try store.add(word, to: bio)
        try store.add(word, to: chem)
        XCTAssertEqual(Set(word.folderList.map(\.name)), ["Biology", "Chemistry"])
    }

    func testDeletingFolderKeepsWords() throws {
        let word = try store.recordLookup(term: "mitosis", definition: "cell division")
        let folder = try store.createFolder(named: "Biology")
        try store.add(word, to: folder)

        try store.deleteFolder(folder)

        let survivor = try store.word(forTerm: "mitosis")
        XCTAssertNotNil(survivor)
        XCTAssertTrue(survivor!.folderList.isEmpty)
    }

    func testDeletingWordRemovesItFromFolders() throws {
        let word = try store.recordLookup(term: "mitosis", definition: "cell division")
        let folder = try store.createFolder(named: "Biology")
        try store.add(word, to: folder)

        try store.delete(word)
        XCTAssertTrue(folder.wordList.isEmpty)
    }
}
