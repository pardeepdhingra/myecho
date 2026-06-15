import Foundation
import Testing
import UIKit
@testable import MyEchoAAC

@MainActor
@Suite("AACStore")
struct AACStoreTests {
    private func makeStore() -> AACStore {
        AACStore(defaults: makeIsolatedDefaults())
    }

    private func makeWord(
        label: String,
        category: String = AACWord.coreCategory,
        position: Int,
        isVisible: Bool = true
    ) -> AACWord {
        AACWord(label: label, symbol: "💬", category: category, colorName: .blue, position: position, isVisible: isVisible)
    }

    // MARK: First launch & persistence

    @Test("Fresh install loads the starter vocabulary and default settings")
    func freshInstallDefaults() {
        let store = makeStore()
        #expect(!store.words.isEmpty)
        #expect(store.words.map(\.label) == StarterVocabulary.words.map(\.label))
        #expect(!store.quickPhrases.isEmpty)
    }

    @Test("Board changes persist and reload from the same defaults")
    func persistenceRoundTrip() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        let word = makeWord(label: "zebra ball", position: 9_999)
        store.upsert(word)
        store.addQuickPhrase("We go home now")

        let reloaded = AACStore(defaults: defaults)
        #expect(reloaded.words.contains { $0.id == word.id && $0.label == "zebra ball" })
        #expect(reloaded.quickPhrases.contains { $0.text == "We go home now" })
    }

    // MARK: Words

    @Test("Upsert appends a new word and updates an existing one in place")
    func upsertInsertAndUpdate() {
        let store = makeStore()
        let countBefore = store.words.count
        var word = makeWord(label: "trampoline", position: 9_999)
        store.upsert(word)
        #expect(store.words.count == countBefore + 1)

        word.label = "big trampoline"
        store.upsert(word)
        #expect(store.words.count == countBefore + 1)
        #expect(store.words.first { $0.id == word.id }?.label == "big trampoline")
    }

    @Test("visibleWords hides hidden tiles, filters by category, and sorts by position")
    func visibleWordsFilterAndSort() {
        let store = makeStore()
        store.replaceAll(
            words: [
                makeWord(label: "b", category: "Play", position: 2),
                makeWord(label: "a", category: "Play", position: 1),
                makeWord(label: "hidden", category: "Play", position: 0, isVisible: false),
                makeWord(label: "core word", position: 3)
            ],
            quickPhrases: [],
            settings: .default
        )
        let visible = store.visibleWords(in: "Play")
        #expect(visible.map(\.label) == ["a", "b"])
        #expect(store.visibleWords(in: nil).map(\.label) == ["a", "b", "core word"])
    }

    @Test("Toggling visibility flips only the targeted word")
    func toggleVisibility() {
        let store = makeStore()
        let word = store.words[0]
        store.toggleVisibility(for: word)
        #expect(store.words.first { $0.id == word.id }?.isVisible == !word.isVisible)
    }

    @Test("Favorites get sequential positions and unfavoriting clears them")
    func favoritesLifecycle() {
        let store = makeStore()
        let first = store.words[0]
        let second = store.words[1]
        store.toggleFavorite(for: first)
        store.toggleFavorite(for: second)
        #expect(store.favoritesOrdered.map(\.id) == [first.id, second.id])

        store.toggleFavorite(for: first)
        #expect(store.favoritesOrdered.map(\.id) == [second.id])
        #expect(store.words.first { $0.id == first.id }?.favoritePosition == nil)
    }

    @Test("Reordering favorites rewrites favoritePosition in the new order")
    func moveFavorites() {
        let store = makeStore()
        let first = store.words[0]
        let second = store.words[1]
        store.toggleFavorite(for: first)
        store.toggleFavorite(for: second)
        store.moveFavorites(from: IndexSet(integer: 1), to: 0)
        #expect(store.favoritesOrdered.map(\.id) == [second.id, first.id])
    }

    @Test("Deleting a word removes it from the board")
    func deleteWord() {
        let store = makeStore()
        let word = makeWord(label: "temporary", position: 9_999)
        store.upsert(word)
        store.delete(word)
        #expect(!store.words.contains { $0.id == word.id })
    }

    @Test("resetStarterBoard restores default words")
    func resetStarterBoardRestoresWords() {
        let store = makeStore()
        store.words = [makeWord(label: "custom", position: 0)]
        store.resetStarterBoard()
        #expect(!store.words.isEmpty)
        #expect(store.words.map(\.label) == StarterVocabulary.words.map(\.label))
    }

    @Test("resetStarterBoard does not delete unrelated ImageStore files")
    func resetStarterBoardSparesCoreImages() throws {
        // Simulate a "scene image" file in ImageStore that isn't a word photo
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        let img = renderer.image { ctx in ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4)) }
        let scenePath = try ImageStore.save(img)
        #expect(ImageStore.exists(scenePath))

        let store = makeStore()
        store.resetStarterBoard()

        #expect(ImageStore.exists(scenePath), "Scene image must survive resetStarterBoard")

        // Cleanup
        ImageStore.delete(scenePath)
    }

    @Test("categories lists each folder once, ordered by first position")
    func categoriesOrderedUnique() {
        let store = makeStore()
        store.replaceAll(
            words: [
                makeWord(label: "one", category: "Food", position: 1),
                makeWord(label: "two", category: "Play", position: 2),
                makeWord(label: "three", category: "Food", position: 3)
            ],
            quickPhrases: [],
            settings: .default
        )
        #expect(store.categories == ["Food", "Play"])
    }

    // MARK: Tile colour resolution

    @Test("A per-button colour override always wins")
    func tileColorOverrideWins() {
        let store = makeStore()
        var word = makeWord(label: "x", category: "Food", position: 1)
        word.colorOverride = .red
        #expect(store.tileColor(for: word) == TileColorName.red.color)
    }

    @Test("Core words colour by word type in folder-colour mode")
    func tileColorCoreWordUsesWordType() {
        let store = makeStore()
        var word = makeWord(label: "go", position: 1)
        word.partOfSpeech = .verb
        #expect(store.settings.colorMode == .byCategory)
        #expect(store.tileColor(for: word) == PartOfSpeech.verb.defaultColor.color)
    }

    @Test("Per-word colour mode uses the word's own colour")
    func tileColorPerWordMode() {
        let store = makeStore()
        store.settings.colorMode = .perWord
        let word = makeWord(label: "x", category: "Food", position: 1)
        #expect(store.tileColor(for: word) == TileColorName.blue.color)
    }

    // MARK: Category styles & folder visibility

    @Test("setCategoryStyle upserts case-insensitively and clearCategoryStyle reverts to default")
    func categoryStyleLifecycle() {
        let store = makeStore()
        store.setCategoryStyle(name: "Food", colorName: .purple, icon: "🍇")
        #expect(store.resolvedCategoryStyle(for: "food").colorName == .purple)

        store.setCategoryStyle(name: "FOOD", colorName: .teal, icon: "🥦")
        #expect(store.settings.categoryStyles.filter { $0.name.caseInsensitiveCompare("Food") == .orderedSame }.count == 1)
        #expect(store.resolvedCategoryStyle(for: "Food").colorName == .teal)

        store.clearCategoryStyle(name: "food")
        #expect(store.explicitCategoryStyle(for: "Food") == nil)
    }

    @Test("Hiding a folder is reversible and case-insensitive")
    func folderVisibility() {
        let store = makeStore()
        store.setFolder("Food", hidden: true)
        #expect(store.isFolderHidden("food"))
        store.setFolder("FOOD", hidden: false)
        #expect(!store.isFolderHidden("Food"))
    }

    // MARK: Routine packs

    @Test("Merging a pack adds its content once; a second merge skips everything")
    func mergePackIdempotent() {
        let store = makeStore()
        store.replaceAll(words: [makeWord(label: "only word", position: 1)], quickPhrases: [], settings: .default)
        let pack = RoutinePacks.food

        let first = store.mergePack(pack)
        #expect(first.wordsAdded == pack.words.count)
        #expect(first.phrasesAdded == pack.phrases.count)

        let second = store.mergePack(pack)
        #expect(second.wordsAdded == 0)
        #expect(second.wordsSkipped == pack.words.count)
        #expect(second.phrasesAdded == 0)
    }

    @Test("Removing a pack removes exactly the items it added")
    func removePack() {
        let store = makeStore()
        store.replaceAll(words: [makeWord(label: "keep me", position: 1)], quickPhrases: [], settings: .default)
        let pack = RoutinePacks.bathroom
        let merge = store.mergePack(pack)

        let removed = store.removePack(pack)
        #expect(removed.wordsRemoved == merge.wordsAdded)
        #expect(removed.phrasesRemoved == merge.phrasesAdded)
        #expect(store.words.map(\.label) == ["keep me"])
    }

    @Test("packCoverage counts missing items before merge and zero after")
    func packCoverage() {
        let store = makeStore()
        store.replaceAll(words: [makeWord(label: "unrelated", position: 1)], quickPhrases: [], settings: .default)
        let pack = RoutinePacks.play

        let before = store.packCoverage(pack)
        #expect(before.wordsMissing == pack.words.count)

        store.mergePack(pack)
        let after = store.packCoverage(pack)
        #expect(after.wordsMissing == 0)
        #expect(after.phrasesMissing == 0)
    }

    @Test("Merging the starter vocabulary into a fresh board skips every word")
    func starterMergeIdempotent() {
        let store = makeStore()
        let result = store.mergeStarterVocabulary()
        #expect(result.wordsAdded == 0)
        #expect(result.wordsSkipped == StarterVocabulary.words.count)
    }

    // MARK: Quick phrases

    @Test("addQuickPhrase trims whitespace and ignores empty input")
    func addQuickPhrase() {
        let store = makeStore()
        let countBefore = store.quickPhrases.count
        store.addQuickPhrase("   We go park   ")
        #expect(store.quickPhrases.last?.text == "We go park")

        store.addQuickPhrase("   ")
        #expect(store.quickPhrases.count == countBefore + 1)
    }

    @Test("Quick phrases can be updated and deleted by identity")
    func quickPhraseUpdateDelete() {
        let store = makeStore()
        store.addQuickPhrase("Hello there")
        guard var phrase = store.quickPhrases.last else {
            Issue.record("Expected a phrase after adding one")
            return
        }
        phrase.text = "Hello friend"
        store.updateQuickPhrase(phrase)
        #expect(store.quickPhrases.last?.text == "Hello friend")

        store.deleteQuickPhrase(phrase)
        #expect(!store.quickPhrases.contains { $0.id == phrase.id })
    }

    @Test("Every regulation button kind exists after ensureRegulationDefaults, with no duplicates")
    func regulationDefaults() {
        let store = makeStore()
        store.replaceAll(words: store.words, quickPhrases: [], settings: .default)
        store.ensureRegulationDefaults()
        for kind in RegulationKind.allCases {
            #expect(store.quickPhrases.filter { $0.mode == .regulation && $0.regulationKind == kind }.count == 1)
        }

        store.ensureRegulationDefaults()
        #expect(store.quickPhrases.filter { $0.mode == .regulation }.count == RegulationKind.allCases.count)
    }
}
