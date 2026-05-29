import Foundation

@MainActor
final class AACStore: ObservableObject {
    @Published var words: [AACWord] {
        didSet { saveWords() }
    }

    @Published var settings: AACSettings {
        didSet { saveSettings() }
    }

    @Published var quickPhrases: [QuickPhrase] {
        didSet { saveQuickPhrases() }
    }

    private let wordsKey = "vani.words.v1"
    private let settingsKey = "vani.settings.v1"
    private let phrasesKey = "vani.phrases.v1"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: wordsKey),
           let storedWords = try? decoder.decode([AACWord].self, from: data),
           !storedWords.isEmpty {
            words = storedWords
        } else {
            words = Self.defaultWords
        }

        if let data = defaults.data(forKey: settingsKey),
           let storedSettings = try? decoder.decode(AACSettings.self, from: data) {
            settings = storedSettings
        } else {
            settings = .default
        }

        if let data = defaults.data(forKey: phrasesKey),
           let stored = try? decoder.decode([QuickPhrase].self, from: data) {
            quickPhrases = stored
        } else {
            quickPhrases = Self.defaultQuickPhrases
        }
    }

    var categories: [String] {
        let ordered = words
            .sorted { $0.position < $1.position }
            .map(\.category)
        return Array(NSOrderedSet(array: ordered)) as? [String] ?? []
    }

    func visibleWords(in category: String?) -> [AACWord] {
        words
            .filter { $0.isVisible }
            .filter { category == nil || $0.category == category }
            .sorted { $0.position < $1.position }
    }

    func upsert(_ word: AACWord) {
        if let index = words.firstIndex(where: { $0.id == word.id }) {
            words[index] = word
        } else {
            words.append(word)
        }
    }

    func addBlankWord() -> AACWord {
        AACWord(
            label: "New word",
            phrase: "New word",
            symbol: "💬",
            category: "Home",
            colorName: .gray,
            position: nextPosition()
        )
    }

    func toggleVisibility(for word: AACWord) {
        guard let index = words.firstIndex(where: { $0.id == word.id }) else { return }
        words[index].isVisible.toggle()
    }

    func toggleFavorite(for word: AACWord) {
        guard let index = words.firstIndex(where: { $0.id == word.id }) else { return }
        words[index].isFavorite.toggle()
        if words[index].isFavorite {
            let nextFavPos = (words.compactMap(\.favoritePosition).max() ?? 0) + 1
            words[index].favoritePosition = nextFavPos
        } else {
            words[index].favoritePosition = nil
        }
    }

    var favoritesOrdered: [AACWord] {
        words
            .filter { $0.isFavorite }
            .sorted { lhs, rhs in
                let l = lhs.favoritePosition ?? Int.max
                let r = rhs.favoritePosition ?? Int.max
                if l != r { return l < r }
                return lhs.position < rhs.position
            }
    }

    func moveFavorites(from offsets: IndexSet, to destination: Int) {
        var ordered = favoritesOrdered
        ordered.move(fromOffsets: offsets, toOffset: destination)
        for (index, word) in ordered.enumerated() {
            if let storeIndex = words.firstIndex(where: { $0.id == word.id }) {
                words[storeIndex].favoritePosition = index + 1
            }
        }
    }

    func move(from offsets: IndexSet, to destination: Int) {
        var ordered = words.sorted { $0.position < $1.position }
        ordered.move(fromOffsets: offsets, toOffset: destination)
        for (index, word) in ordered.enumerated() {
            if let storeIndex = words.firstIndex(where: { $0.id == word.id }) {
                words[storeIndex].position = index + 1
            }
        }
    }

    func moveWords(ids: [UUID], from offsets: IndexSet, to destination: Int) {
        var ids = ids
        ids.move(fromOffsets: offsets, toOffset: destination)
        for (index, id) in ids.enumerated() {
            if let storeIndex = words.firstIndex(where: { $0.id == id }) {
                words[storeIndex].position = index + 1
            }
        }
    }

    func delete(_ word: AACWord) {
        if let filename = word.imagePath {
            ImageStore.delete(filename)
        }
        words.removeAll { $0.id == word.id }
    }

    struct PackMergeResult {
        let wordsAdded: Int
        let wordsSkipped: Int
        let phrasesAdded: Int
        let phrasesSkipped: Int
    }

    @discardableResult
    func mergePack(_ pack: RoutinePack) -> PackMergeResult {
        var addedWords = 0
        var skippedWords = 0
        let existingLabels = Set(words.map { $0.label.lowercased() })
        var nextPos = nextPosition()
        for var word in pack.words {
            if existingLabels.contains(word.label.lowercased()) {
                skippedWords += 1
                continue
            }
            word.position = nextPos
            word.sourcePackId = pack.id
            nextPos += 1
            words.append(word)
            addedWords += 1
        }
        var addedPhrases = 0
        var skippedPhrases = 0
        let existingPhrases = Set(quickPhrases.map { $0.text.lowercased() })
        var nextPhrasePos = (quickPhrases.map(\.position).max() ?? 0) + 1
        for var phrase in pack.phrases {
            if existingPhrases.contains(phrase.text.lowercased()) {
                skippedPhrases += 1
                continue
            }
            phrase.position = nextPhrasePos
            phrase.sourcePackId = pack.id
            nextPhrasePos += 1
            quickPhrases.append(phrase)
            addedPhrases += 1
        }
        return PackMergeResult(
            wordsAdded: addedWords,
            wordsSkipped: skippedWords,
            phrasesAdded: addedPhrases,
            phrasesSkipped: skippedPhrases
        )
    }

    @discardableResult
    func removePack(_ pack: RoutinePack) -> (wordsRemoved: Int, phrasesRemoved: Int) {
        var removedWords = 0
        var removedPhrases = 0
        let wordsToRemove = words.filter { $0.sourcePackId == pack.id }
        for word in wordsToRemove {
            if let filename = word.imagePath {
                ImageStore.delete(filename)
            }
            removedWords += 1
        }
        words.removeAll { $0.sourcePackId == pack.id }
        removedPhrases = quickPhrases.filter { $0.sourcePackId == pack.id }.count
        quickPhrases.removeAll { $0.sourcePackId == pack.id }
        return (removedWords, removedPhrases)
    }

    func packStatus(_ pack: RoutinePack) -> (addedWords: Int, addedPhrases: Int) {
        let addedWords = words.filter { $0.sourcePackId == pack.id }.count
        let addedPhrases = quickPhrases.filter { $0.sourcePackId == pack.id }.count
        return (addedWords, addedPhrases)
    }

    func packCoverage(_ pack: RoutinePack) -> (wordsMissing: Int, phrasesMissing: Int) {
        let existingLabels = Set(words.map { $0.label.lowercased() })
        let existingPhrases = Set(quickPhrases.map { $0.text.lowercased() })
        let wordsMissing = pack.words.reduce(0) { existingLabels.contains($1.label.lowercased()) ? $0 : $0 + 1 }
        let phrasesMissing = pack.phrases.reduce(0) { existingPhrases.contains($1.text.lowercased()) ? $0 : $0 + 1 }
        return (wordsMissing, phrasesMissing)
    }

    func resetStarterBoard() {
        ImageStore.purgeAll()
        words = Self.defaultWords
        settings = .default
        quickPhrases = Self.defaultQuickPhrases
    }

    func addQuickPhrase(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let next = (quickPhrases.map(\.position).max() ?? 0) + 1
        quickPhrases.append(QuickPhrase(text: trimmed, position: next))
    }

    func updateQuickPhrase(_ phrase: QuickPhrase) {
        guard let index = quickPhrases.firstIndex(where: { $0.id == phrase.id }) else { return }
        quickPhrases[index] = phrase
    }

    func deleteQuickPhrase(_ phrase: QuickPhrase) {
        quickPhrases.removeAll { $0.id == phrase.id }
    }

    func moveQuickPhrase(from offsets: IndexSet, to destination: Int) {
        var ordered = quickPhrases.sorted { $0.position < $1.position }
        ordered.move(fromOffsets: offsets, toOffset: destination)
        for (index, phrase) in ordered.enumerated() {
            if let storeIndex = quickPhrases.firstIndex(where: { $0.id == phrase.id }) {
                quickPhrases[storeIndex].position = index + 1
            }
        }
    }

    private func nextPosition() -> Int {
        (words.map(\.position).max() ?? 0) + 1
    }

    private func saveWords() {
        guard let data = try? encoder.encode(words) else { return }
        UserDefaults.standard.set(data, forKey: wordsKey)
    }

    private func saveSettings() {
        guard let data = try? encoder.encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: settingsKey)
    }

    private func saveQuickPhrases() {
        guard let data = try? encoder.encode(quickPhrases) else { return }
        UserDefaults.standard.set(data, forKey: phrasesKey)
    }

    static let defaultQuickPhrases: [QuickPhrase] = [
        QuickPhrase(text: "I need a break", position: 1, mode: .regulation, regulationKind: .calm),
        QuickPhrase(text: "I need help", position: 2, mode: .regulation, regulationKind: .help),
        QuickPhrase(text: "Please stop", position: 3, mode: .regulation, regulationKind: .stop),
        QuickPhrase(text: "I want water", position: 4),
        QuickPhrase(text: "I need toilet", position: 5),
        QuickPhrase(text: "I am hungry", position: 6),
        QuickPhrase(text: "I love you", position: 7)
    ]

    func ensureRegulationDefaults() {
        var nextPos = (quickPhrases.map(\.position).max() ?? 0) + 1
        for kind in RegulationKind.allCases {
            if !quickPhrases.contains(where: { $0.mode == .regulation && $0.regulationKind == kind }) {
                let defaultText: String
                switch kind {
                case .calm: defaultText = "I need a break"
                case .help: defaultText = "I need help"
                case .stop: defaultText = "Please stop"
                }
                quickPhrases.append(QuickPhrase(text: defaultText, position: nextPos, mode: .regulation, regulationKind: kind))
                nextPos += 1
            }
        }
    }

    static let defaultWords: [AACWord] = [
        AACWord(label: "I", symbol: "👤", category: "Home", colorName: .blue, position: 1),
        AACWord(label: "want", symbol: "👉", category: "Home", colorName: .green, position: 2),
        AACWord(label: "more", symbol: "➕", category: "Home", colorName: .green, position: 3),
        AACWord(label: "all done", symbol: "✅", category: "Home", colorName: .orange, position: 4),
        AACWord(label: "yes", symbol: "👍", category: "Home", colorName: .teal, position: 5),
        AACWord(label: "no", symbol: "✋", category: "Home", colorName: .pink, position: 6),
        AACWord(label: "help", symbol: "🫶", category: "Home", colorName: .yellow, position: 7),
        AACWord(label: "stop", symbol: "🛑", category: "Home", colorName: .orange, position: 8),
        AACWord(label: "go", symbol: "➡️", category: "Home", colorName: .green, position: 9),
        AACWord(label: "look", symbol: "👀", category: "Home", colorName: .blue, position: 10),
        AACWord(label: "like", symbol: "💛", category: "Home", colorName: .yellow, position: 11),
        AACWord(label: "not like", symbol: "💔", category: "Home", colorName: .pink, position: 12),
        AACWord(label: "happy", symbol: "😊", category: "Feelings", colorName: .yellow, position: 13),
        AACWord(label: "sad", symbol: "😢", category: "Feelings", colorName: .blue, position: 14),
        AACWord(label: "angry", symbol: "😠", category: "Feelings", colorName: .orange, position: 15),
        AACWord(label: "scared", symbol: "😟", category: "Feelings", colorName: .purple, position: 16),
        AACWord(label: "hurt", symbol: "🤕", category: "Feelings", colorName: .pink, position: 17),
        AACWord(label: "tired", symbol: "😴", category: "Feelings", colorName: .gray, position: 18),
        AACWord(label: "eat", symbol: "🍽️", category: "Needs", colorName: .green, position: 19),
        AACWord(label: "drink", symbol: "🥤", category: "Needs", colorName: .teal, position: 20),
        AACWord(label: "toilet", symbol: "🚽", category: "Needs", colorName: .blue, position: 21),
        AACWord(label: "break", symbol: "🧘", category: "Needs", colorName: .purple, position: 22),
        AACWord(label: "play", symbol: "🧸", category: "Play", colorName: .yellow, position: 23),
        AACWord(label: "music", symbol: "🎵", category: "Play", colorName: .pink, position: 24),
        AACWord(label: "outside", symbol: "🌳", category: "Play", colorName: .green, position: 25),
        AACWord(label: "book", symbol: "📖", category: "Play", colorName: .orange, position: 26),
        AACWord(label: "mum", symbol: "❤️", category: "People", colorName: .pink, position: 27),
        AACWord(label: "dad", symbol: "⭐️", category: "People", colorName: .blue, position: 28),
        AACWord(label: "home", symbol: "🏠", category: "Places", colorName: .teal, position: 29),
        AACWord(label: "school", symbol: "🏫", category: "Places", colorName: .orange, position: 30)
    ]
}
