import Foundation

/// Next-word suggestions for the kid board, in the spirit of the prediction bars in leading AAC apps.
///
/// Learns word→word transitions (bigrams) from the child's own taps, so suggestions reflect how THIS
/// child actually talks. A small built-in seed of common core-word pairs covers the cold start. All
/// data stays on-device in `UserDefaults`.
@MainActor
final class PredictionService: ObservableObject {
    /// Context token used when the message bar is empty — sentence starters get their own bucket.
    static let sentenceStart = "^start"

    /// Learned (and seeded) transition counts: lowercased previous label → next label → count.
    @Published private(set) var transitions: [String: [String: Int]]

    private let defaults: UserDefaults
    private let key = "vani.predictions.v1"
    /// Keep the table small: at most this many distinct next-words per context.
    private let maxNextPerContext = 50

    /// Cold-start pairs reflecting common early-communication patterns. Seeded with count 1 so any
    /// real usage immediately outweighs them.
    static let seedPairs: [(previous: String, next: String)] = [
        (sentenceStart, "I"), (sentenceStart, "more"), (sentenceStart, "want"),
        ("i", "want"), ("i", "like"), ("i", "go"),
        ("want", "more"), ("want", "eat"), ("want", "play"),
        ("more", "please"), ("go", "play"), ("like", "it")
    ]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let stored = try? JSONDecoder().decode([String: [String: Int]].self, from: data) {
            transitions = stored
        } else {
            var seeded: [String: [String: Int]] = [:]
            for pair in Self.seedPairs {
                seeded[pair.previous.lowercased(), default: [:]][pair.next] = 1
            }
            transitions = seeded
        }
    }

    /// Record one tap: the child added `next` after `previous` (nil = start of a message).
    func recordTransition(from previous: String?, to next: String) {
        let context = (previous ?? Self.sentenceStart).lowercased()
        let nextLabel = next.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nextLabel.isEmpty else { return }

        var bucket = transitions[context, default: [:]]
        bucket[nextLabel, default: 0] += 1
        if bucket.count > maxNextPerContext {
            // Drop the rarest entries so the hot pairs survive.
            let keep = bucket.sorted { $0.value > $1.value }.prefix(maxNextPerContext)
            bucket = Dictionary(uniqueKeysWithValues: Array(keep))
        }
        transitions[context] = bucket
        save()
    }

    /// The best next words after `previous` (nil = sentence start), drawn from `candidates`.
    /// Context-specific counts rank first; remaining slots fill by overall frequency across contexts.
    func suggestions(after previous: String?, candidates: [AACWord], limit: Int = 4) -> [AACWord] {
        guard limit > 0, !candidates.isEmpty else { return [] }
        let context = (previous ?? Self.sentenceStart).lowercased()
        let byLabel = Dictionary(grouping: candidates) { $0.label.lowercased() }

        var picked: [AACWord] = []
        var usedLabels = Set<String>()

        let contextCounts = transitions[context] ?? [:]
        for (label, _) in contextCounts.sorted(by: { $0.value > $1.value }) {
            guard picked.count < limit else { break }
            let lower = label.lowercased()
            guard !usedLabels.contains(lower), let word = byLabel[lower]?.first else { continue }
            usedLabels.insert(lower)
            picked.append(word)
        }

        if picked.count < limit {
            var globalCounts: [String: Int] = [:]
            for (_, bucket) in transitions {
                for (label, count) in bucket {
                    globalCounts[label.lowercased(), default: 0] += count
                }
            }
            for (label, _) in globalCounts.sorted(by: { $0.value > $1.value }) {
                guard picked.count < limit else { break }
                guard !usedLabels.contains(label), let word = byLabel[label]?.first else { continue }
                usedLabels.insert(label)
                picked.append(word)
            }
        }

        return picked
    }

    /// Forget everything learned (and restore the cold-start seeds).
    func reset() {
        var seeded: [String: [String: Int]] = [:]
        for pair in Self.seedPairs {
            seeded[pair.previous.lowercased(), default: [:]][pair.next] = 1
        }
        transitions = seeded
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(transitions) else { return }
        defaults.set(data, forKey: key)
    }
}
