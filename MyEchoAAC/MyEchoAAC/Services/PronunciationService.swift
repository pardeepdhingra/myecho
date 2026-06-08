import Foundation

enum PronunciationService {
    private static let phraseOverrides: [String: String] = [
        "ice cream": "ise kreem",
        "mum": "mumm",
        "dad": "dadd",
        "toilet": "toy lit",
        "all done": "all dun",
        "not like": "not lyke",
        "i need toilet": "I need toy lit"
    ]

    private static let wordOverrides: [String: String] = [
        "cream": "kreem",
        "done": "dun",
        "like": "lyke",
        "mum": "mumm",
        "dad": "dadd",
        "toilet": "toy lit"
    ]

    static func suggestion(for label: String) -> String? {
        let normalized = normalize(label)
        guard !normalized.isEmpty else { return nil }

        if let exact = phraseOverrides[normalized] {
            return exact
        }

        let words = normalized.split(separator: " ").map(String.init)
        let spokenWords = words.map { wordOverrides[$0] ?? simplePhoneticWord($0) }
        let suggestion = spokenWords.joined(separator: " ")
        return suggestion.caseInsensitiveCompare(label.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
            ? nil
            : suggestion
    }

    static func bestSpokenPhrase(for label: String) -> String {
        suggestion(for: label) ?? label.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .joined(separator: " ")
    }

    private static func simplePhoneticWord(_ word: String) -> String {
        var result = word
        let replacements: [(String, String)] = [
            ("ice", "ise"),
            ("igh", "eye"),
            ("ph", "f"),
            ("ck", "k"),
            ("qu", "kw"),
            ("c", "k")
        ]
        for (from, to) in replacements {
            result = result.replacingOccurrences(of: from, with: to)
        }
        return result
    }
}
