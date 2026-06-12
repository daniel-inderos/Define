import XCTest
@testable import Define

final class TermNormalizerTests: XCTestCase {
    func testTrimsWhitespace() {
        XCTAssertEqual(TermNormalizer.normalize("  apple  "), "apple")
    }

    func testStripsTrailingSentencePunctuation() {
        XCTAssertEqual(TermNormalizer.normalize("apple."), "apple")
        XCTAssertEqual(TermNormalizer.normalize("apple,"), "apple")
        XCTAssertEqual(TermNormalizer.normalize("apple!?"), "apple")
    }

    func testStripsWrappingQuotesAndBrackets() {
        XCTAssertEqual(TermNormalizer.normalize("“apple”"), "apple")
        XCTAssertEqual(TermNormalizer.normalize("(apple)"), "apple")
        XCTAssertEqual(TermNormalizer.normalize("[apple]"), "apple")
    }

    func testKeepsInternalPunctuation() {
        XCTAssertEqual(TermNormalizer.normalize("doesn't"), "doesn't")
        XCTAssertEqual(TermNormalizer.normalize("mother-in-law"), "mother-in-law")
        XCTAssertEqual(TermNormalizer.normalize("don’t"), "don’t")
    }

    func testCollapsesInternalWhitespace() {
        XCTAssertEqual(TermNormalizer.normalize("give   up"), "give up")
        XCTAssertEqual(TermNormalizer.normalize("give\tup"), "give up")
    }

    func testTakesFirstNonEmptyLine() {
        XCTAssertEqual(TermNormalizer.normalize("\n\napple\nbanana"), "apple")
    }

    func testRejectsEmptyAndNil() {
        XCTAssertNil(TermNormalizer.normalize(nil))
        XCTAssertNil(TermNormalizer.normalize(""))
        XCTAssertNil(TermNormalizer.normalize("   \n  "))
        XCTAssertNil(TermNormalizer.normalize("“”"))
    }

    func testRejectsOverlongSelections() {
        let paragraph = String(repeating: "word ", count: 50)
        XCTAssertNil(TermNormalizer.normalize(paragraph))
    }

    func testAllowsMultiWordPhrases() {
        XCTAssertEqual(TermNormalizer.normalize("bring about"), "bring about")
    }
}
