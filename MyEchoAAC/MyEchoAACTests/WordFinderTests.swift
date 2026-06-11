import Foundation
import Testing
@testable import MyEchoAAC

@MainActor
@Suite("WordFinder — searchWords")
struct WordFinderTests {
    private func makeStore(words: [AACWord] = []) -> AACStore {
        let store = AACStore(defaults: makeIsolatedDefaults())
        store.words = words
        return store
    }

    private func word(
        _ label: String,
        phrase: String? = nil,
        category: String = "Food",
        visible: Bool = true,
        position: Int = 1
    ) -> AACWord {
        AACWord(
            label: label,
            phrase: phrase ?? label,
            symbol: "💬",
            category: category,
            colorName: .blue,
            position: position,
            isVisible: visible
        )
    }

    // MARK: Basic matching

    @Test("Empty query returns empty results")
    func emptyQueryReturnsEmpty() {
        let store = makeStore(words: [word("apple")])
        #expect(store.searchWords(matching: "").isEmpty)
        #expect(store.searchWords(matching: "   ").isEmpty)
    }

    @Test("Exact label match (case-insensitive)")
    func exactLabelMatch() {
        let store = makeStore(words: [word("Apple"), word("banana")])
        let results = store.searchWords(matching: "apple")
        #expect(results.count == 1)
        #expect(results[0].label == "Apple")
    }

    @Test("Partial label match")
    func partialLabelMatch() {
        let store = makeStore(words: [word("apple"), word("pineapple"), word("banana")])
        let results = store.searchWords(matching: "appl")
        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.label.lowercased().contains("appl") })
    }

    @Test("Phrase-only match (label does not contain query)")
    func phraseOnlyMatch() {
        let store = makeStore(words: [word("more", phrase: "I want more")])
        let results = store.searchWords(matching: "want")
        #expect(results.count == 1)
        #expect(results[0].label == "more")
    }

    // MARK: Visibility filter

    @Test("Hidden words are excluded from results")
    func hiddenWordsExcluded() {
        let store = makeStore(words: [word("apple", visible: true), word("avocado", visible: false)])
        let results = store.searchWords(matching: "a")
        #expect(results.allSatisfy { $0.isVisible })
        #expect(!results.contains { $0.label == "avocado" })
    }

    // MARK: Ranking

    @Test("Prefix matches rank before substring matches")
    func prefixRankFirst() {
        let store = makeStore(words: [
            word("pineapple", position: 1),
            word("apple", position: 2),
        ])
        let results = store.searchWords(matching: "apple")
        #expect(results.first?.label == "apple")
        #expect(results.last?.label == "pineapple")
    }

    @Test("Among same-rank results, alphabetical order is stable")
    func alphabeticalAmongSameRank() {
        let store = makeStore(words: [
            word("mango", position: 3),
            word("apple", position: 1),
            word("banana", position: 2),
        ])
        let labels = store.searchWords(matching: "a").map(\.label)
        #expect(labels == labels.sorted())
    }

    // MARK: Core path label

    @Test("pathLabel for core word returns 'Core'")
    func pathLabelCore() {
        let w = AACWord(
            label: "more",
            symbol: "➕",
            category: AACWord.coreCategory,
            colorName: .blue,
            position: 1
        )
        #expect(AACStore.pathLabel(for: w) == "Core")
    }

    @Test("pathLabel for folder word returns category name")
    func pathLabelFolder() {
        let w = AACWord(
            label: "apple",
            symbol: "🍎",
            category: "Food",
            colorName: .orange,
            position: 1
        )
        #expect(AACStore.pathLabel(for: w) == "Food")
    }
}
