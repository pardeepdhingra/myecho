import Foundation
import Testing
@testable import MyEchoAAC

@MainActor
@Suite("UsageHistory")
struct UsageHistoryTests {
    @Test("Recording a tap stores an entry; disabled tracking stores nothing")
    func recordRespectsEnabledFlag() {
        let history = UsageHistory(defaults: makeIsolatedDefaults())
        let id = UUID()
        history.record(wordId: id, label: "more", enabled: true)
        history.record(wordId: UUID(), label: "stop", enabled: false)
        #expect(history.totalCount == 1)
        #expect(history.entries.first?.wordId == id)
    }

    @Test("Entries persist and reload from the same defaults")
    func persistenceRoundTrip() {
        let defaults = makeIsolatedDefaults()
        let history = UsageHistory(defaults: defaults)
        history.record(wordId: UUID(), label: "help", enabled: true)
        history.recordSentence("I want juice", enabled: true)

        let reloaded = UsageHistory(defaults: defaults)
        #expect(reloaded.totalCount == 1)
        #expect(reloaded.spokenSentences == ["I want juice"])
    }

    @Test("countsInLast groups by label and sorts by frequency")
    func countsGroupAndSort() {
        let history = UsageHistory(defaults: makeIsolatedDefaults())
        let moreId = UUID()
        history.record(wordId: moreId, label: "more", enabled: true)
        history.record(wordId: moreId, label: "more", enabled: true)
        history.record(wordId: UUID(), label: "stop", enabled: true)

        let counts = history.countsInLast(hours: 24)
        #expect(counts.first?.label == "more")
        #expect(counts.first?.count == 2)
        #expect(counts.count == 2)
    }

    @Test("recentWordIds returns most recent first, deduplicated, capped at the limit")
    func recentWordIds() {
        let history = UsageHistory(defaults: makeIsolatedDefaults())
        let a = UUID(), b = UUID(), c = UUID()
        history.record(wordId: a, label: "a", enabled: true)
        history.record(wordId: b, label: "b", enabled: true)
        history.record(wordId: a, label: "a", enabled: true)
        history.record(wordId: c, label: "c", enabled: true)

        #expect(history.recentWordIds(limit: 10) == [c, a, b])
        #expect(history.recentWordIds(limit: 2) == [c, a])
    }

    @Test("Repeating a sentence moves it to the front instead of duplicating")
    func sentenceDeduplication() {
        let history = UsageHistory(defaults: makeIsolatedDefaults())
        history.recordSentence("I want water", enabled: true)
        history.recordSentence("I need a break", enabled: true)
        history.recordSentence("I want water", enabled: true)
        #expect(history.spokenSentences == ["I want water", "I need a break"])
    }

    @Test("Sentence history trims whitespace, skips empties, and caps at 25")
    func sentenceLimits() {
        let history = UsageHistory(defaults: makeIsolatedDefaults())
        history.recordSentence("   ", enabled: true)
        #expect(history.spokenSentences.isEmpty)

        for index in 1...30 {
            history.recordSentence("sentence \(index)", enabled: true)
        }
        #expect(history.spokenSentences.count == 25)
        #expect(history.spokenSentences.first == "sentence 30")
    }

    @Test("clear and clearSentences empty their stores")
    func clearing() {
        let history = UsageHistory(defaults: makeIsolatedDefaults())
        history.record(wordId: UUID(), label: "x", enabled: true)
        history.recordSentence("hello", enabled: true)
        history.clear()
        history.clearSentences()
        #expect(history.totalCount == 0)
        #expect(history.spokenSentences.isEmpty)
    }

    @Test("sessionReport includes child name, word counts, and sentences")
    func sessionReport() {
        let history = UsageHistory(defaults: makeIsolatedDefaults())
        history.record(wordId: UUID(), label: "more", enabled: true)
        history.record(wordId: UUID(), label: "more", enabled: true)
        history.record(wordId: UUID(), label: "help", enabled: true)
        history.recordSentence("I want juice", enabled: true)

        let report = history.sessionReport(childName: "Alex")

        #expect(report.contains("Alex"))
        #expect(report.contains("more"))
        #expect(report.contains("2"))
        #expect(report.contains("I want juice"))
        #expect(report.contains("Vani"))
    }

    @Test("sessionReport works without a child name")
    func sessionReportNoName() {
        let history = UsageHistory(defaults: makeIsolatedDefaults())
        let report = history.sessionReport(childName: nil)
        #expect(report.contains("Vani"))
        #expect(!report.isEmpty)
    }

    @Test("importAll replaces entries and sentences wholesale")
    func importAll() {
        let history = UsageHistory(defaults: makeIsolatedDefaults())
        history.record(wordId: UUID(), label: "old", enabled: true)
        let entry = UsageHistory.Entry(wordId: UUID(), label: "new")
        history.importAll(entries: [entry], spokenSentences: ["restored"])
        #expect(history.entries.map(\.id) == [entry.id])
        #expect(history.spokenSentences == ["restored"])
    }
}
