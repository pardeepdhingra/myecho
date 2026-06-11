import Foundation
import Testing
@testable import MyEchoAAC

@MainActor
@Suite("BulkSign")
struct BulkSignTests {

    private func makeStore(words: [AACWord]) -> AACStore {
        let store = AACStore(defaults: makeIsolatedDefaults())
        store.words = words
        return store
    }

    private func word(_ label: String, hasSign: Bool = false, visible: Bool = true) -> AACWord {
        AACWord(
            label: label,
            symbol: "💬",
            category: "Actions",
            colorName: .green,
            position: 1,
            isVisible: visible,
            signVideoPath: hasSign ? "some-sign.mp4" : nil
        )
    }

    @Test func unsignedWordsExcludesWordWithSign() {
        let store = makeStore(words: [
            word("eat", hasSign: true),
            word("play"),
            word("jump")
        ])
        let unsigned = store.words.filter { $0.isVisible && $0.signVideoPath == nil }
        #expect(unsigned.count == 2)
        #expect(!unsigned.map(\.label).contains("eat"))
    }

    @Test func unsignedWordsExcludesHidden() {
        let store = makeStore(words: [
            word("secret", hasSign: false, visible: false),
            word("play")
        ])
        let unsigned = store.words.filter { $0.isVisible && $0.signVideoPath == nil }
        #expect(unsigned.count == 1)
        #expect(unsigned[0].label == "play")
    }

    @Test func unsignedWordsEmptyWhenAllSigned() {
        let store = makeStore(words: [
            word("eat", hasSign: true),
            word("play", hasSign: true)
        ])
        let unsigned = store.words.filter { $0.isVisible && $0.signVideoPath == nil }
        #expect(unsigned.isEmpty)
    }

    @Test func unsignedWordsAllWhenNoneSigned() {
        let store = makeStore(words: [
            word("eat"),
            word("play"),
            word("jump")
        ])
        let unsigned = store.words.filter { $0.isVisible && $0.signVideoPath == nil }
        #expect(unsigned.count == 3)
    }
}
