import Foundation

/// Cleans up raw selected text into something worth looking up.
/// Selections arrive messy — trailing punctuation, smart quotes, stray
/// newlines from PDFs — and the dictionary wants a clean term.
enum TermNormalizer {
    /// Maximum length we'll attempt to look up. Anything longer is almost
    /// certainly an accidental paragraph selection, not a term.
    static let maxLength = 100

    static func normalize(_ raw: String?) -> String? {
        guard let raw else { return nil }

        // Take the first non-empty line; multi-line selections are usually
        // accidents, but the first line often still contains the wanted word.
        guard var term = raw
            .components(separatedBy: .newlines)
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .first(where: { !$0.isEmpty })
        else { return nil }

        // Collapse internal runs of whitespace ("give   up" → "give up").
        term = term
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        // Strip wrapping punctuation but keep internal punctuation —
        // "doesn't", "mother-in-law", and "e.g." should survive.
        let wrapping = CharacterSet.punctuationCharacters
            .union(.symbols)
            .subtracting(CharacterSet(charactersIn: "-'’."))
        term = term.trimmingCharacters(in: wrapping)
        // Trailing sentence punctuation is never part of the term.
        while let last = term.unicodeScalars.last,
              CharacterSet(charactersIn: ".,;:!?").contains(last) {
            term.removeLast()
        }
        term = term.trimmingCharacters(in: .whitespaces)

        guard !term.isEmpty, term.count <= maxLength else { return nil }
        return term
    }
}
