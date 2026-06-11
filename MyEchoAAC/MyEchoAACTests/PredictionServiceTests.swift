import Foundation
import Testing
@testable import MyEchoAAC

@MainActor
@Suite("PredictionService")
struct PredictionServiceTests {
    private func makeWord(_ label: String) -> AACWord {
        AACWord(label: label, symbol: "💬", category: AACWord.coreCategory, colorName: .blue, position: 1)
    }

    private func makeService() -> PredictionService {
        PredictionService(defaults: makeIsolatedDefaults())
    }

    @Test("Learned transitions outrank everything else for their context")
    func learnedTransitionsRankFirst() {
        let service = makeService()
        let candidates = ["want", "milk", "play", "go"].map(makeWord)
        for _ in 1...5 { service.recordTransition(from: "I", to: "milk") }
        service.recordTransition(from: "I", to: "play")

        let suggested = service.suggestions(after: "I", candidates: candidates, limit: 2)
        #expect(suggested.first?.label == "milk")
        #expect(suggested.count == 2)
    }

    @Test("Sentence start has its own context")
    func sentenceStartContext() {
        let service = makeService()
        let candidates = ["mum", "want", "I"].map(makeWord)
        for _ in 1...5 { service.recordTransition(from: nil, to: "mum") }

        let suggested = service.suggestions(after: nil, candidates: candidates, limit: 1)
        #expect(suggested.first?.label == "mum")
    }

    @Test("Cold start suggests seeded core-word pairs")
    func coldStartSeeds() {
        let service = makeService()
        let candidates = ["want", "zebra", "like"].map(makeWord)
        let suggested = service.suggestions(after: "I", candidates: candidates, limit: 2)
        #expect(Set(suggested.map(\.label)).isSubset(of: ["want", "like", "go"]))
        #expect(!suggested.isEmpty)
    }

    @Test("Suggestions only contain words from the candidate list")
    func candidatesRespected() {
        let service = makeService()
        for _ in 1...3 { service.recordTransition(from: "I", to: "hidden word") }
        let candidates = ["want"].map(makeWord)

        let suggested = service.suggestions(after: "I", candidates: candidates, limit: 4)
        #expect(suggested.allSatisfy { $0.label == "want" })
    }

    @Test("Unknown context falls back to overall frequency")
    func unknownContextFallsBack() {
        let service = makeService()
        for _ in 1...10 { service.recordTransition(from: "banana", to: "smoothie") }
        let candidates = ["smoothie", "zebra"].map(makeWord)

        let suggested = service.suggestions(after: "completely new word", candidates: candidates, limit: 1)
        #expect(suggested.first?.label == "smoothie")
    }

    @Test("Limit is respected and duplicates never appear")
    func limitAndUniqueness() {
        let service = makeService()
        for _ in 1...3 { service.recordTransition(from: "I", to: "want") }
        service.recordTransition(from: "go", to: "want")
        let candidates = ["want", "go", "play", "more", "milk"].map(makeWord)

        let suggested = service.suggestions(after: "I", candidates: candidates, limit: 3)
        #expect(suggested.count == 3)
        #expect(Set(suggested.map(\.label)).count == 3)
    }

    @Test("Learned transitions persist across instances on the same defaults")
    func persistenceRoundTrip() {
        let defaults = makeIsolatedDefaults()
        let first = PredictionService(defaults: defaults)
        for _ in 1...5 { first.recordTransition(from: "I", to: "milk") }

        let reloaded = PredictionService(defaults: defaults)
        let suggested = reloaded.suggestions(after: "I", candidates: [makeWord("milk"), makeWord("want")], limit: 1)
        #expect(suggested.first?.label == "milk")
    }

    @Test("Context matching is case-insensitive")
    func caseInsensitiveContext() {
        let service = makeService()
        for _ in 1...3 { service.recordTransition(from: "WANT", to: "milk") }
        let suggested = service.suggestions(after: "want", candidates: [makeWord("milk"), makeWord("go")], limit: 1)
        #expect(suggested.first?.label == "milk")
    }

    @Test("A context never stores more than the per-context cap")
    func perContextCap() {
        let service = makeService()
        for index in 1...60 {
            service.recordTransition(from: "I", to: "word \(index)")
        }
        #expect((service.transitions["i"]?.count ?? 0) <= 50)
    }

    @Test("Reset restores the cold-start seeds")
    func resetRestoresSeeds() {
        let service = makeService()
        for _ in 1...9 { service.recordTransition(from: "I", to: "zebra") }
        service.reset()
        let suggested = service.suggestions(after: "I", candidates: [makeWord("zebra"), makeWord("want")], limit: 1)
        #expect(suggested.first?.label == "want")
    }

    @Test("Settings from older boards decode with word suggestions enabled")
    func settingsMigrationDefaultsOn() throws {
        var settings = AACSettings.default
        settings.showWordSuggestions = true
        var json = try #require(String(data: JSONEncoder().encode(settings), encoding: .utf8))
        json = json.replacingOccurrences(of: "\"showWordSuggestions\":true,", with: "")
        json = json.replacingOccurrences(of: ",\"showWordSuggestions\":true", with: "")

        let decoded = try JSONDecoder().decode(AACSettings.self, from: Data(json.utf8))
        #expect(decoded.showWordSuggestions)
    }
}
