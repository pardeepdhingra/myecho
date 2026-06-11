import Testing
@testable import MyEchoAAC

@MainActor @Suite("QuickReveal")
struct QuickRevealTests {

    // MARK: - allWords(in:)

    @Test("allWords(in:) includes hidden words")
    func allWordsIncludesHidden() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        store.words = [
            AACWord(label: "yes", phrase: "yes", symbol: "✅", category: "Core", colorName: .green, position: 0, isVisible: true),
            AACWord(label: "no", phrase: "no", symbol: "❌", category: "Core", colorName: .red, position: 1, isVisible: false),
        ]
        let all = store.allWords(in: "Core")
        #expect(all.count == 2)
    }

    @Test("allWords(in:) excludes other categories")
    func allWordsFiltersByCategory() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        store.words = [
            AACWord(label: "eat", phrase: "eat", symbol: "🍴", category: "Food", colorName: .orange, position: 0),
            AACWord(label: "yes", phrase: "yes", symbol: "✅", category: "Core", colorName: .green, position: 1),
            AACWord(label: "drink", phrase: "drink", symbol: "🥤", category: "Food", colorName: .orange, position: 2, isVisible: false),
        ]
        let food = store.allWords(in: "Food")
        #expect(food.count == 2)
        #expect(food.allSatisfy { $0.category == "Food" })
    }

    @Test("allWords(in:) returns words sorted by position")
    func allWordsSortedByPosition() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        store.words = [
            AACWord(label: "c", phrase: "c", symbol: "C", category: "Core", colorName: .gray, position: 2),
            AACWord(label: "a", phrase: "a", symbol: "A", category: "Core", colorName: .gray, position: 0),
            AACWord(label: "b", phrase: "b", symbol: "B", category: "Core", colorName: .gray, position: 1),
        ]
        let all = store.allWords(in: "Core")
        #expect(all.map(\.label) == ["a", "b", "c"])
    }

    @Test("allWords(in: nil) returns all words across categories")
    func allWordsNilCategoryReturnsAll() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        store.words = [
            AACWord(label: "eat", phrase: "eat", symbol: "🍴", category: "Food", colorName: .orange, position: 0),
            AACWord(label: "yes", phrase: "yes", symbol: "✅", category: "Core", colorName: .green, position: 1, isVisible: false),
        ]
        let all = store.allWords(in: nil)
        #expect(all.count == 2)
    }

    // MARK: - visible count helper

    @Test("visibleCount reflects actual isVisible flags")
    func visibleCountIsCorrect() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        store.words = [
            AACWord(label: "a", phrase: "a", symbol: "A", category: "Food", colorName: .orange, position: 0, isVisible: true),
            AACWord(label: "b", phrase: "b", symbol: "B", category: "Food", colorName: .orange, position: 1, isVisible: false),
            AACWord(label: "c", phrase: "c", symbol: "C", category: "Food", colorName: .orange, position: 2, isVisible: true),
        ]
        let food = store.allWords(in: "Food")
        let visibleCount = food.filter(\.isVisible).count
        #expect(visibleCount == 2)
    }

    // MARK: - toggleVisibility

    @Test("toggleVisibility hides a visible word")
    func toggleHidesWord() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        let word = AACWord(label: "hello", phrase: "hello", symbol: "👋", category: "Core", colorName: .blue, position: 0, isVisible: true)
        store.words = [word]
        store.toggleVisibility(for: word)
        #expect(store.words.first?.isVisible == false)
    }

    @Test("toggleVisibility reveals a hidden word")
    func toggleRevealsWord() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        let word = AACWord(label: "hello", phrase: "hello", symbol: "👋", category: "Core", colorName: .blue, position: 0, isVisible: false)
        store.words = [word]
        store.toggleVisibility(for: word)
        #expect(store.words.first?.isVisible == true)
    }

    // MARK: - freezeButtonPositions auto-enable

    @Test("freezeButtonPositions can be enabled via settings")
    func freezeCanBeEnabled() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        #expect(store.settings.freezeButtonPositions == false)
        store.settings.freezeButtonPositions = true
        #expect(store.settings.freezeButtonPositions == true)
    }
}
