import Foundation

/// `DCSCopyTextDefinition` returns the whole entry as one run-together
/// plain-text blob ("apple | ˈapəl | noun 1 the round fruit… 2 the tree…
/// ORIGIN Old English…"). This applies best-effort line breaks so the
/// entry reads like a dictionary entry again.
///
/// The heuristics are deliberately conservative: a missed break is better
/// than a wrong one in the middle of a sentence.
enum DefinitionFormatter {
    private static let sectionHeaders = [
        "PHRASAL VERBS", "PHRASES", "DERIVATIVES", "ORIGIN", "USAGE",
    ]

    static func format(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Break before all-caps section headers: "… tree. ORIGIN Old English"
        for header in sectionHeaders {
            text = text.replacingOccurrences(
                of: #"\s+\#(header)\s+"#,
                with: "\n\n\(header)\n",
                options: .regularExpression
            )
        }

        // Break before sub-entry and sense markers Apple's dictionaries use.
        text = text.replacingOccurrences(
            of: #"\s*▶\s*"#, with: "\n\n▶ ", options: .regularExpression)
        text = text.replacingOccurrences(
            of: #"\s+•\s*"#, with: "\n• ", options: .regularExpression)

        // Numbered senses: "noun 1 the round fruit… flesh. 2 the tree…".
        // Only break when the number follows a part of speech or
        // sentence-ending punctuation, so years and quantities in running
        // text ("over 100 species") are left alone.
        let pos = "noun|verb|adjective|adverb|exclamation|interjection|preposition|conjunction|pronoun|determiner|abbreviation|symbol|suffix|prefix"
        text = text.replacingOccurrences(
            of: #"(\b(?:\#(pos))|[.;:|\])”"]) (\d{1,2}) "#,
            with: "$1\n$2  ",
            options: .regularExpression
        )

        // Put the pronunciation on its own line: "apple | ˈapəl | noun …"
        text = text.replacingOccurrences(
            of: #"^([^|\n]+?) \| ([^|\n]+) \| "#,
            with: "$1\n| $2 |\n",
            options: .regularExpression
        )

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
