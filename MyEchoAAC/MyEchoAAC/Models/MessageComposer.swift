import Foundation

/// The sentence the child is building in the message bar.
///
/// Pure state + rules, kept out of `KidModeView` so the core communication flow is unit-testable.
/// Each tap becomes its own `Entry` with a fresh identity, so the same word can appear twice in a
/// message ("more more") without breaking SwiftUI's `ForEach` identity.
@MainActor
final class MessageComposer: ObservableObject {
    /// One tapped word in the message. Identity is per-tap, not per-word.
    struct Entry: Identifiable {
        let id: UUID
        let word: AACWord

        init(id: UUID = UUID(), word: AACWord) {
            self.id = id
            self.word = word
        }
    }

    @Published private(set) var entries: [Entry] = []

    var isEmpty: Bool { entries.isEmpty }

    var words: [AACWord] { entries.map(\.word) }

    /// The raw spoken phrase — each word's phrase joined with spaces.
    var phrase: String { entries.map(\.word.phrase).joined(separator: " ") }

    /// The sentence as it should be spoken aloud: trimmed, with a full stop added when the child's
    /// words don't already end in terminal punctuation. Nil when there is nothing to say.
    var polishedSentence: String? {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let last = trimmed.last, ".?!".contains(last) {
            return trimmed
        }
        return trimmed + "."
    }

    func append(_ word: AACWord) {
        entries.append(Entry(word: word))
    }

    func removeLast() {
        guard !entries.isEmpty else { return }
        entries.removeLast()
    }

    func clear() {
        entries.removeAll()
    }
}
