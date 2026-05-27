import Foundation

@MainActor
final class AACStore: ObservableObject {
    @Published var words: [AACWord] {
        didSet { saveWords() }
    }

    @Published var settings: AACSettings {
        didSet { saveSettings() }
    }

    private let wordsKey = "myechoaac.words.v1"
    private let settingsKey = "myechoaac.settings.v1"
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

    func delete(_ word: AACWord) {
        words.removeAll { $0.id == word.id }
    }

    func resetStarterBoard() {
        words = Self.defaultWords
        settings = .default
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
