import Foundation
import Testing
@testable import MyEchoAAC

@MainActor
@Suite("BoardSetStore")
struct BoardSetStoreTests {
    private func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("board-sets-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeStore() -> AACStore {
        AACStore(defaults: makeIsolatedDefaults())
    }

    private func makeWord(label: String, position: Int) -> AACWord {
        AACWord(label: label, symbol: "💬", category: AACWord.coreCategory, colorName: .blue, position: position)
    }

    @Test("Saving the current board creates a named set with correct metadata")
    func saveCreatesSet() {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = makeStore()
        let boardSets = BoardSetStore(directory: dir)

        let meta = boardSets.saveCurrentBoard(named: "  School  ", store: store)
        #expect(meta?.name == "School")
        #expect(meta?.wordCount == store.words.count)
        #expect(boardSets.sets.count == 1)
    }

    @Test("Saving with an empty name is rejected")
    func saveRejectsEmptyName() {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let boardSets = BoardSetStore(directory: dir)

        #expect(boardSets.saveCurrentBoard(named: "   ", store: makeStore()) == nil)
        #expect(boardSets.sets.isEmpty)
    }

    @Test("Loading a set restores the saved board into another store")
    func loadRoundTrip() {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let boardSets = BoardSetStore(directory: dir)

        let original = makeStore()
        original.replaceAll(
            words: [makeWord(label: "school word", position: 1)],
            quickPhrases: [QuickPhrase(text: "Time for class", position: 1)],
            settings: .default
        )
        guard let meta = boardSets.saveCurrentBoard(named: "School", store: original) else {
            Issue.record("Expected save to succeed")
            return
        }

        let target = makeStore()
        #expect(boardSets.load(id: meta.id, into: target))
        #expect(target.words.map(\.label) == ["school word"])
        #expect(target.quickPhrases.map(\.text) == ["Time for class"])
    }

    @Test("The set index survives a new store instance over the same directory")
    func indexPersists() {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let first = BoardSetStore(directory: dir)
        first.saveCurrentBoard(named: "Home", store: makeStore())
        first.saveCurrentBoard(named: "Therapy", store: makeStore())

        let reloaded = BoardSetStore(directory: dir)
        #expect(reloaded.sets.map(\.name) == ["Home", "Therapy"])
    }

    @Test("Index entries whose backing file is missing are dropped on load")
    func missingFilesPruned() {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let first = BoardSetStore(directory: dir)
        guard let meta = first.saveCurrentBoard(named: "Home", store: makeStore()) else {
            Issue.record("Expected save to succeed")
            return
        }
        try? FileManager.default.removeItem(at: dir.appendingPathComponent("\(meta.id.uuidString).vaniboard"))

        let reloaded = BoardSetStore(directory: dir)
        #expect(reloaded.sets.isEmpty)
    }

    @Test("Overwriting a set updates its contents and metadata")
    func updateSet() {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let boardSets = BoardSetStore(directory: dir)
        let store = makeStore()
        guard let meta = boardSets.saveCurrentBoard(named: "Home", store: store) else {
            Issue.record("Expected save to succeed")
            return
        }

        store.replaceAll(words: [makeWord(label: "only one", position: 1)], quickPhrases: [], settings: .default)
        #expect(boardSets.updateSet(id: meta.id, from: store))
        #expect(boardSets.sets.first?.wordCount == 1)

        let target = makeStore()
        #expect(boardSets.load(id: meta.id, into: target))
        #expect(target.words.map(\.label) == ["only one"])
    }

    @Test("Rename trims whitespace and rejects empty names")
    func rename() {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let boardSets = BoardSetStore(directory: dir)
        guard let meta = boardSets.saveCurrentBoard(named: "Home", store: makeStore()) else {
            Issue.record("Expected save to succeed")
            return
        }

        boardSets.rename(id: meta.id, to: "  Weekend  ")
        #expect(boardSets.sets.first?.name == "Weekend")

        boardSets.rename(id: meta.id, to: "   ")
        #expect(boardSets.sets.first?.name == "Weekend")
    }

    @Test("Delete removes both the index entry and the set file")
    func delete() {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let boardSets = BoardSetStore(directory: dir)
        guard let meta = boardSets.saveCurrentBoard(named: "Home", store: makeStore()) else {
            Issue.record("Expected save to succeed")
            return
        }

        boardSets.delete(id: meta.id)
        #expect(boardSets.sets.isEmpty)
        let file = dir.appendingPathComponent("\(meta.id.uuidString).vaniboard")
        #expect(!FileManager.default.fileExists(atPath: file.path))
    }

    @Test("Loading an unknown or corrupt set fails without changing the store")
    func loadFailureLeavesStoreUntouched() {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let boardSets = BoardSetStore(directory: dir)
        let store = makeStore()
        let labelsBefore = store.words.map(\.label)

        #expect(!boardSets.load(id: UUID(), into: store))
        #expect(store.words.map(\.label) == labelsBefore)
    }
}
