import XCTest
@testable import Define

final class AnkiExporterTests: XCTestCase {
    func testIncludesAnkiFileHeaders() {
        let tsv = AnkiExporter.tsv(cards: [.init(front: "apple", back: "a fruit")], deckName: "Biology")
        let lines = tsv.components(separatedBy: "\n")
        XCTAssertEqual(lines[0], "#separator:tab")
        XCTAssertEqual(lines[1], "#html:true")
        XCTAssertEqual(lines[2], "#deck:Biology")
        XCTAssertEqual(lines[3], "#columns:Front\tBack")
    }

    func testOmitsDeckHeaderWhenNoDeckName() {
        let tsv = AnkiExporter.tsv(cards: [.init(front: "a", back: "b")])
        XCTAssertFalse(tsv.contains("#deck:"))
    }

    func testCardLineIsTabSeparated() {
        let tsv = AnkiExporter.tsv(cards: [.init(front: "apple", back: "a fruit")])
        XCTAssertTrue(tsv.contains("apple\ta fruit\n"))
    }

    func testEscapesNewlinesAsHTMLBreaks() {
        XCTAssertEqual(AnkiExporter.escapeField("line one\nline two"), "line one<br>line two")
        XCTAssertEqual(AnkiExporter.escapeField("a\r\nb"), "a<br>b")
    }

    func testEscapesTabsToSpaces() {
        XCTAssertEqual(AnkiExporter.escapeField("a\tb"), "a b")
    }

    func testEscapesHTMLMetacharacters() {
        XCTAssertEqual(AnkiExporter.escapeField("1 < 2 & 3 > 2"), "1 &lt; 2 &amp; 3 &gt; 2")
    }

    func testSanitizesDeckNameInHeader() {
        let tsv = AnkiExporter.tsv(cards: [], deckName: "Bio\tlogy")
        XCTAssertTrue(tsv.contains("#deck:Bio logy"))
    }

    func testEndsWithTrailingNewline() {
        let tsv = AnkiExporter.tsv(cards: [.init(front: "a", back: "b")])
        XCTAssertTrue(tsv.hasSuffix("\n"))
        XCTAssertFalse(tsv.hasSuffix("\n\n"))
    }
}
