import XCTest
@testable import Define

final class DefinitionFormatterTests: XCTestCase {
    func testBreaksBeforeSectionHeaders() {
        let raw = "apple noun a fruit. ORIGIN Old English æppel, of Germanic origin."
        let formatted = DefinitionFormatter.format(raw)
        XCTAssertTrue(formatted.contains("\n\nORIGIN\n"), "got: \(formatted)")
    }

    func testBreaksNumberedSensesAfterPartOfSpeech() {
        let raw = "apple | ˈapəl | noun 1 the round fruit of a tree. 2 the tree which bears apples."
        let formatted = DefinitionFormatter.format(raw)
        XCTAssertTrue(formatted.contains("noun\n1  the round fruit"), "got: \(formatted)")
        XCTAssertTrue(formatted.contains("tree.\n2  the tree"), "got: \(formatted)")
    }

    func testLeavesNumbersInRunningTextAlone() {
        let raw = "century noun a period of 100 years."
        let formatted = DefinitionFormatter.format(raw)
        XCTAssertTrue(formatted.contains("of 100 years"), "got: \(formatted)")
    }

    func testPronunciationGetsItsOwnLine() {
        let raw = "apple | ˈapəl | noun 1 the round fruit."
        let formatted = DefinitionFormatter.format(raw)
        XCTAssertTrue(formatted.hasPrefix("apple\n| ˈapəl |"), "got: \(formatted)")
    }

    func testBreaksBeforeBullets() {
        let raw = "run verb 1 move fast. • move about in a hurried way."
        let formatted = DefinitionFormatter.format(raw)
        XCTAssertTrue(formatted.contains("\n• move about"), "got: \(formatted)")
    }

    func testBreaksBeforeSubEntryMarkers() {
        let raw = "give verb hand over. ▶ give up stop trying."
        let formatted = DefinitionFormatter.format(raw)
        XCTAssertTrue(formatted.contains("\n\n▶ give up"), "got: \(formatted)")
    }

    func testTrimsSurroundingWhitespace() {
        XCTAssertEqual(DefinitionFormatter.format("  word noun a thing.  "), "word noun a thing.")
    }

    func testPlainTextWithoutMarkersIsUntouched() {
        let raw = "hello exclamation used as a greeting."
        XCTAssertEqual(DefinitionFormatter.format(raw), raw)
    }
}
