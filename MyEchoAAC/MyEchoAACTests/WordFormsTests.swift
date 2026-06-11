import Foundation
import Testing
@testable import MyEchoAAC

@Suite("WordForms")
struct WordFormsTests {
    private func makeWord(label: String, forms: [String] = []) -> AACWord {
        AACWord(
            label: label,
            symbol: "💬",
            category: "Action",
            colorName: .green,
            position: 1,
            wordForms: forms
        )
    }

    // MARK: Data model

    @Test("Word with no forms has empty wordForms")
    func emptyFormsByDefault() {
        let w = AACWord(label: "eat", symbol: "🍴", category: "Action", colorName: .green, position: 1)
        #expect(w.wordForms.isEmpty)
    }

    @Test("Word forms round-trip through JSON")
    func jsonRoundTrip() throws {
        let original = makeWord(label: "eat", forms: ["eating", "ate", "eats"])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AACWord.self, from: data)
        #expect(decoded.wordForms == ["eating", "ate", "eats"])
    }

    @Test("Decoding a word without wordForms key defaults to empty")
    func backwardsCompatDecode() throws {
        let json = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "label": "eat",
          "phrase": "eat",
          "symbol": "🍴",
          "category": "Action",
          "colorName": "green",
          "position": 1,
          "isVisible": true,
          "isFavorite": false
        }
        """.data(using: .utf8)!
        let word = try JSONDecoder().decode(AACWord.self, from: json)
        #expect(word.wordForms.isEmpty)
    }

    // MARK: Starter vocabulary seeding

    @Test("StarterVocabulary seeds 'eat' with common verb forms")
    @MainActor
    func eatIsSeeded() {
        let eat = StarterVocabulary.words.first { $0.label.lowercased() == "eat" }
        #expect(eat != nil)
        let forms = eat?.wordForms ?? []
        #expect(forms.contains("eating"))
        #expect(forms.contains("ate"))
        #expect(forms.contains("eats"))
    }

    @Test("StarterVocabulary seeds 'play' with verb forms")
    @MainActor
    func playIsSeeded() {
        let play = StarterVocabulary.words.first { $0.label.lowercased() == "play" }
        #expect(play != nil)
        let forms = play?.wordForms ?? []
        #expect(forms.contains("playing"))
        #expect(forms.contains("played"))
    }

    @Test("Words without applicable forms have empty wordForms")
    @MainActor
    func coreWordsHaveNoForms() {
        // Core words like "I", "you", "the" typically have no forms
        let i = StarterVocabulary.words.first { $0.label == "I" }
        if let i {
            #expect(i.wordForms.isEmpty)
        }
    }
}
