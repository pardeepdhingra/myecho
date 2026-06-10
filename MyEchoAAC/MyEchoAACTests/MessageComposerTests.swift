import Foundation
import Testing
@testable import MyEchoAAC

@MainActor
@Suite("MessageComposer")
struct MessageComposerTests {
    private func word(_ label: String, phrase: String? = nil) -> AACWord {
        AACWord(label: label, phrase: phrase, symbol: "💬", category: AACWord.coreCategory, colorName: .blue, position: 1)
    }

    @Test("Starts empty with no sentence to speak")
    func startsEmpty() {
        let composer = MessageComposer()
        #expect(composer.isEmpty)
        #expect(composer.phrase.isEmpty)
        #expect(composer.polishedSentence == nil)
    }

    @Test("Appending words builds the phrase in tap order")
    func buildsPhrase() {
        let composer = MessageComposer()
        composer.append(word("I"))
        composer.append(word("want"))
        composer.append(word("water"))
        #expect(composer.phrase == "I want water")
        #expect(composer.words.map(\.label) == ["I", "want", "water"])
    }

    @Test("The same word can appear twice with distinct entry identities")
    func duplicateWordsKeepDistinctIdentity() {
        let composer = MessageComposer()
        let more = word("more")
        composer.append(more)
        composer.append(more)
        #expect(composer.phrase == "more more")
        #expect(composer.entries.count == 2)
        #expect(composer.entries[0].id != composer.entries[1].id)
    }

    @Test("Speaking uses each word's spoken phrase, not its label")
    func usesSpokenPhrase() {
        let composer = MessageComposer()
        composer.append(word("like", phrase: "lyke"))
        #expect(composer.phrase == "lyke")
    }

    @Test("A full stop is added when the sentence has no terminal punctuation")
    func polishAddsFullStop() {
        let composer = MessageComposer()
        composer.append(word("I"))
        composer.append(word("want"))
        composer.append(word("water"))
        #expect(composer.polishedSentence == "I want water.")
    }

    @Test("Existing terminal punctuation is preserved", arguments: ["where are you?", "stop!", "all done."])
    func polishKeepsExistingPunctuation(text: String) {
        let composer = MessageComposer()
        composer.append(word(text, phrase: text))
        #expect(composer.polishedSentence == text)
    }

    @Test("removeLast drops only the most recent word and is safe when empty")
    func removeLast() {
        let composer = MessageComposer()
        composer.removeLast()
        #expect(composer.isEmpty)

        composer.append(word("I"))
        composer.append(word("want"))
        composer.removeLast()
        #expect(composer.phrase == "I")
    }

    @Test("clear empties the whole message")
    func clear() {
        let composer = MessageComposer()
        composer.append(word("I"))
        composer.append(word("want"))
        composer.clear()
        #expect(composer.isEmpty)
        #expect(composer.polishedSentence == nil)
    }
}
