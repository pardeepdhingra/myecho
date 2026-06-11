import Foundation
import Testing
@testable import MyEchoAAC

@MainActor
@Suite("KeyboardPage")
struct KeyboardPageTests {

    @Test func typeAheadFindsVocabWord() {
        let store = AACStore(defaults: makeIsolatedDefaults())
        _ = store.mergeStarterVocabulary()
        let results = store.searchWords(matching: "eat")
        #expect(!results.isEmpty)
        #expect(results[0].label.lowercased().hasPrefix("eat"))
    }

    @Test func typeAheadEmptyQueryReturnsEmpty() {
        let store = AACStore(defaults: makeIsolatedDefaults())
        _ = store.mergeStarterVocabulary()
        #expect(store.searchWords(matching: "").isEmpty)
    }

    @Test func typeAheadExcludesHiddenWords() {
        let store = AACStore(defaults: makeIsolatedDefaults())
        let hidden = AACWord(
            label: "secretword",
            phrase: "secretword",
            symbol: "🔒",
            category: "Test",
            colorName: .gray,
            position: 1,
            isVisible: false
        )
        store.upsert(hidden)
        #expect(store.searchWords(matching: "secretword").isEmpty)
    }

    @Test func typeAheadPrefixRanksFirst() {
        let store = AACStore(defaults: makeIsolatedDefaults())
        _ = store.mergeStarterVocabulary()
        let results = store.searchWords(matching: "play")
        #expect(!results.isEmpty)
        #expect(results[0].label.lowercased() == "play")
    }

    @Test func showKeyboardPageDefaultIsTrue() {
        #expect(AACSettings.default.showKeyboardPage == true)
    }
}
