import Testing
@testable import MyEchoAAC

@Suite("PronunciationService")
struct PronunciationServiceTests {
    @Test("Known phrases use their hand-tuned override")
    func phraseOverride() {
        #expect(PronunciationService.suggestion(for: "ice cream") == "ise kreem")
        #expect(PronunciationService.suggestion(for: "all done") == "all dun")
    }

    @Test("Lookup is case-insensitive and ignores surrounding whitespace")
    func normalization() {
        #expect(PronunciationService.suggestion(for: "  Ice Cream  ") == "ise kreem")
        #expect(PronunciationService.suggestion(for: "ALL DONE") == "all dun")
    }

    @Test("Hyphens and underscores are treated as word separators")
    func separatorNormalization() {
        #expect(PronunciationService.suggestion(for: "all-done") == "all dun")
        #expect(PronunciationService.suggestion(for: "all_done") == "all dun")
    }

    @Test("Single-word overrides apply inside multi-word labels")
    func wordOverrideInsidePhrase() {
        #expect(PronunciationService.suggestion(for: "i need toilet") == "I need toy lit")
    }

    @Test("Words that already speak correctly return no suggestion")
    func noSuggestionWhenUnchanged() {
        #expect(PronunciationService.suggestion(for: "ball") == nil)
        #expect(PronunciationService.suggestion(for: "water") == nil)
    }

    @Test("Empty and whitespace-only labels return no suggestion")
    func emptyLabel() {
        #expect(PronunciationService.suggestion(for: "") == nil)
        #expect(PronunciationService.suggestion(for: "   ") == nil)
    }

    @Test("bestSpokenPhrase falls back to the trimmed label")
    func bestSpokenPhraseFallback() {
        #expect(PronunciationService.bestSpokenPhrase(for: "  ball  ") == "ball")
        #expect(PronunciationService.bestSpokenPhrase(for: "ice cream") == "ise kreem")
    }

    @Test("Simple phonetic rules rewrite tricky spellings", arguments: [
        ("quick", "kwik"),
        ("phone", "fone"),
        ("night light", "neyet leyet")
    ])
    func phoneticRules(input: String, expected: String) {
        #expect(PronunciationService.bestSpokenPhrase(for: input) == expected)
    }
}
