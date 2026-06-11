import Testing
@testable import MyEchoAAC

@MainActor @Suite("ParentWordFinder")
struct ParentWordFinderTests {

    // MARK: - locationInfo(for:)

    @Test("locationInfo returns category, 1-based rank and total")
    func locationInfoRankAndTotal() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        store.words = [
            AACWord(label: "eat", phrase: "eat", symbol: "🍴", category: "Food", colorName: .orange, position: 0),
            AACWord(label: "drink", phrase: "drink", symbol: "🥤", category: "Food", colorName: .orange, position: 1),
            AACWord(label: "pizza", phrase: "pizza", symbol: "🍕", category: "Food", colorName: .orange, position: 2),
        ]
        let pizza = store.words.first(where: { $0.label == "pizza" })!
        let info = store.locationInfo(for: pizza)
        #expect(info.category == "Food")
        #expect(info.rank == 3)
        #expect(info.total == 3)
    }

    @Test("locationInfo rank reflects position order, not insertion order")
    func locationInfoUsesPositionOrder() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        let first = AACWord(label: "apple", phrase: "apple", symbol: "🍎", category: "Food", colorName: .orange, position: 0)
        let second = AACWord(label: "banana", phrase: "banana", symbol: "🍌", category: "Food", colorName: .orange, position: 1)
        store.words = [second, first]
        let info = store.locationInfo(for: first)
        #expect(info.rank == 1)
    }

    @Test("locationInfo counts only words in same category")
    func locationInfoCategoryIsolated() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        store.words = [
            AACWord(label: "yes", phrase: "yes", symbol: "✅", category: "Core", colorName: .green, position: 0),
            AACWord(label: "no", phrase: "no", symbol: "❌", category: "Core", colorName: .red, position: 1),
            AACWord(label: "eat", phrase: "eat", symbol: "🍴", category: "Food", colorName: .orange, position: 2),
        ]
        let eatWord = store.words.first(where: { $0.label == "eat" })!
        let info = store.locationInfo(for: eatWord)
        #expect(info.total == 1)
        #expect(info.rank == 1)
    }

    @Test("locationInfo includes hidden words in total")
    func locationInfoIncludesHidden() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        store.words = [
            AACWord(label: "a", phrase: "a", symbol: "A", category: "Food", colorName: .orange, position: 0, isVisible: true),
            AACWord(label: "b", phrase: "b", symbol: "B", category: "Food", colorName: .orange, position: 1, isVisible: false),
            AACWord(label: "c", phrase: "c", symbol: "C", category: "Food", colorName: .orange, position: 2, isVisible: true),
        ]
        let b = store.words.first(where: { $0.label == "b" })!
        let info = store.locationInfo(for: b)
        #expect(info.total == 3)
        #expect(info.rank == 2)
    }

    // MARK: - searchWords (already existing, verify for parent finder context)

    @Test("searchWords matches phrase as well as label")
    func searchMatchesPhrase() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        store.words = [
            AACWord(label: "wee-wee", phrase: "toilet", symbol: "🚽", category: "Bathroom", colorName: .blue, position: 0),
        ]
        let results = store.searchWords(matching: "toilet")
        #expect(results.count == 1)
    }

    @Test("searchWords is case-insensitive")
    func searchCaseInsensitive() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        store.words = [
            AACWord(label: "Eat", phrase: "Eat", symbol: "🍴", category: "Food", colorName: .orange, position: 0),
        ]
        #expect(store.searchWords(matching: "eat").count == 1)
        #expect(store.searchWords(matching: "EAT").count == 1)
    }
}
