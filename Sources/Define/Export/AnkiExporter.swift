import Foundation

/// Builds Anki-importable TSV: one note per line, term on the front,
/// definition on the back. The leading `#` directives are file headers
/// Anki (2.1.54+) reads to preconfigure the import — separator, HTML
/// handling, and target deck — so importing a folder is a single step.
enum AnkiExporter {
    struct Card {
        let front: String
        let back: String
    }

    static func tsv(cards: [Card], deckName: String? = nil) -> String {
        var lines = [
            "#separator:tab",
            "#html:true",
        ]
        if let deckName, !deckName.isEmpty {
            lines.append("#deck:\(sanitizeHeaderValue(deckName))")
        }
        lines.append("#columns:Front\tBack")
        for card in cards {
            lines.append("\(escapeField(card.front))\t\(escapeField(card.back))")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func tsv(for words: [Word], deckName: String? = nil) -> String {
        tsv(
            cards: words.map { Card(front: $0.term, back: $0.definition) },
            deckName: deckName
        )
    }

    /// TSV fields cannot contain raw tabs or newlines. Since the file
    /// declares `#html:true`, newlines become `<br>` and render correctly
    /// in Anki; angle brackets in the text are escaped so they aren't
    /// interpreted as markup.
    static func escapeField(_ field: String) -> String {
        field
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\r\n", with: "<br>")
            .replacingOccurrences(of: "\n", with: "<br>")
            .replacingOccurrences(of: "\r", with: "<br>")
    }

    private static func sanitizeHeaderValue(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }
}
