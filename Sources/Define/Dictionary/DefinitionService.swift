import Foundation
import CoreServices

/// Looks up definitions in the user's active system dictionaries via
/// DictionaryServices — the same offline data the built-in
/// "Look Up" popover uses. No network, no API keys.
enum DefinitionService {
    struct Lookup {
        let term: String
        let definition: String
    }

    /// Returns a formatted definition for the term, trying a few simple
    /// variants (exact, lowercased) before giving up.
    static func lookUp(_ term: String) -> Lookup? {
        var candidates = [term]
        let lowercased = term.lowercased()
        if lowercased != term {
            candidates.append(lowercased)
        }

        for candidate in candidates {
            if let raw = rawDefinition(for: candidate) {
                return Lookup(term: candidate, definition: DefinitionFormatter.format(raw))
            }
        }
        return nil
    }

    private static func rawDefinition(for term: String) -> String? {
        let range = CFRange(location: 0, length: term.utf16.count)
        guard let unmanaged = DCSCopyTextDefinition(nil, term as CFString, range) else {
            return nil
        }
        return unmanaged.takeRetainedValue() as String
    }
}
