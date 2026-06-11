import Foundation
import SwiftUI

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
    private var defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

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

        applyPronunciationDefaultsIfNeeded()
    }

    func reload(from newDefaults: UserDefaults) {
        defaults = newDefaults
        if let data = defaults.data(forKey: wordsKey),
           let stored = try? decoder.decode([AACWord].self, from: data),
           !stored.isEmpty {
            words = stored
        } else {
            words = Self.defaultWords
        }
        if let data = defaults.data(forKey: settingsKey),
           let stored = try? decoder.decode(AACSettings.self, from: data) {
            settings = stored
        } else {
            settings = .default
        }
        if let data = defaults.data(forKey: phrasesKey),
           let stored = try? decoder.decode([QuickPhrase].self, from: data) {
            quickPhrases = stored
        } else {
            quickPhrases = Self.defaultQuickPhrases
        }
        applyPronunciationDefaultsIfNeeded()
    }

    var categories: [String] {
        let ordered = words
            .sorted { $0.position < $1.position }
            .map(\.category)
        return Array(NSOrderedSet(array: ordered)) as? [String] ?? []
    }

    /// The parent-customized style for a category, if one exists.
    func explicitCategoryStyle(for name: String) -> CategoryStyle? {
        settings.categoryStyles.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// Resolved color + icon for a category — the parent's choice if set, otherwise a stable default.
    func resolvedCategoryStyle(for name: String) -> ResolvedCategoryStyle {
        if let explicit = explicitCategoryStyle(for: name) {
            return ResolvedCategoryStyle(colorName: explicit.colorName, icon: explicit.icon)
        }
        return CategoryDefaults.defaultStyle(for: name)
    }

    /// The background color a tile should render with. An explicit per-button override always wins;
    /// otherwise the board's `colorMode` decides (by default the word's **folder colour**).
    func tileColor(for word: AACWord) -> Color {
        if let override = word.colorOverride { return override.color }
        // Core/pinned words have no folder identity — in the default "by folder" mode colour them by
        // word type (Fitzgerald Key, the AAC convention) so they aren't a flat grey.
        if settings.colorMode == .byCategory, word.category == AACWord.coreCategory,
           let pos = word.partOfSpeech {
            return pos.defaultColor.color
        }
        switch settings.colorMode {
        case .byCategory:
            return resolvedCategoryStyle(for: word.category).color
        case .perWord:
            return word.colorName.color
        case .byWordType:
            // Untagged words fall back to their own colour so the board never goes blank/grey.
            return (word.partOfSpeech?.defaultColor ?? word.colorName).color
        }
    }

    /// Upsert a parent-customized style for a category.
    func setCategoryStyle(name: String, colorName: TileColorName, icon: String) {
        let trimmedIcon = icon.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedIcon = trimmedIcon.isEmpty ? resolvedCategoryStyle(for: name).icon : trimmedIcon
        if let index = settings.categoryStyles.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            settings.categoryStyles[index].colorName = colorName
            settings.categoryStyles[index].icon = resolvedIcon
        } else {
            settings.categoryStyles.append(
                CategoryStyle(name: name, colorName: colorName, icon: resolvedIcon)
            )
        }
    }

    /// Whether a folder (category) is hidden from the kid board.
    func isFolderHidden(_ name: String) -> Bool {
        settings.isCategoryHidden(name)
    }

    /// Hide or show a whole folder on the kid board (keeps its words; reversible).
    func setFolder(_ name: String, hidden: Bool) {
        var hiddenSet = settings.hiddenCategories.filter { $0.caseInsensitiveCompare(name) != .orderedSame }
        if hidden { hiddenSet.append(name) }
        settings.hiddenCategories = hiddenSet
    }

    /// Remove a parent-customized style so the category reverts to its deterministic default.
    func clearCategoryStyle(name: String) {
        settings.categoryStyles.removeAll { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    // MARK: - Word search

    /// Returns visible words whose label or phrase contains `query` (case-insensitive, trimmed).
    /// Prefix matches rank before substring matches; ties are resolved alphabetically.
    /// Returns `[]` for blank queries.
    func searchWords(matching query: String) -> [AACWord] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let lower = trimmed.lowercased()
        return words
            .filter { $0.isVisible }
            .filter {
                $0.label.lowercased().contains(lower) ||
                $0.phrase.lowercased().contains(lower)
            }
            .sorted { lhs, rhs in
                let lPrefix = lhs.label.lowercased().hasPrefix(lower)
                let rPrefix = rhs.label.lowercased().hasPrefix(lower)
                if lPrefix != rPrefix { return lPrefix }
                return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }
    }

    /// Human-readable path for a word (used in search results). Core words are always visible;
    /// other words live inside their category folder.
    static func pathLabel(for word: AACWord) -> String {
        word.category == AACWord.coreCategory ? "Core" : word.category
    }

    func visibleWords(in category: String?) -> [AACWord] {
        words
            .filter { $0.isVisible }
            .filter { category == nil || $0.category == category }
            .sorted { $0.position < $1.position }
    }

    func allWords(in category: String?) -> [AACWord] {
        words
            .filter { category == nil || $0.category == category }
            .sorted { $0.position < $1.position }
    }

    struct WordLocationInfo {
        let category: String
        let rank: Int
        let total: Int
    }

    func locationInfo(for word: AACWord) -> WordLocationInfo {
        let peers = allWords(in: word.category)
        let rank = (peers.firstIndex(where: { $0.id == word.id }) ?? 0) + 1
        return WordLocationInfo(category: word.category, rank: rank, total: peers.count)
    }

    func upsert(_ word: AACWord) {
        if let index = words.firstIndex(where: { $0.id == word.id }) {
            words[index] = word
        } else {
            words.append(word)
        }
    }

    func addBlankWord() -> AACWord {
        let label = "New word"
        return AACWord(
            label: label,
            phrase: PronunciationService.bestSpokenPhrase(for: label),
            symbol: "💬",
            category: AACWord.coreCategory,
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
        if let signFilename = word.signVideoPath {
            SignVideoStore.delete(signFilename)
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
            if let signFilename = word.signVideoPath {
                SignVideoStore.delete(signFilename)
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
        SignVideoStore.purgeAll()
        words = Self.defaultWords
        settings = .default
        quickPhrases = Self.defaultQuickPhrases
    }

    /// Replace the whole board in one shot (used when restoring a cloud snapshot). Each property's
    /// `didSet` still persists to UserDefaults; the cloud layer suppresses the resulting upload echo
    /// via its content-hash guard.
    func replaceAll(words: [AACWord], quickPhrases: [QuickPhrase], settings: AACSettings) {
        self.words = words
        self.quickPhrases = quickPhrases
        self.settings = settings
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

    private func applyPronunciationDefaultsIfNeeded() {
        for index in words.indices {
            let label = words[index].label.trimmingCharacters(in: .whitespacesAndNewlines)
            let phrase = words[index].phrase.trimmingCharacters(in: .whitespacesAndNewlines)
            guard phrase.isEmpty || phrase.caseInsensitiveCompare(label) == .orderedSame else { continue }
            if let suggestion = PronunciationService.suggestion(for: label) {
                words[index].phrase = suggestion
            }
        }
    }

    private func saveWords() {
        guard let data = try? encoder.encode(words) else { return }
        defaults.set(data, forKey: wordsKey)
    }

    private func saveSettings() {
        guard let data = try? encoder.encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }

    private func saveQuickPhrases() {
        guard let data = try? encoder.encode(quickPhrases) else { return }
        defaults.set(data, forKey: phrasesKey)
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

    /// The starter board for fresh installs — the broad, folder-organized, word-type-tagged
    /// vocabulary (see `StarterVocabulary`). Existing users keep their saved board; they can pull in
    /// any missing words via `mergeStarterVocabulary()`.
    static var defaultWords: [AACWord] { StarterVocabulary.words }

    struct StarterMergeResult {
        let wordsAdded: Int
        let wordsSkipped: Int
    }

    /// Additively merge the built-in starter vocabulary, skipping any word whose label already exists
    /// (case-insensitive). New words are appended with fresh positions so existing tiles never move —
    /// safe to run repeatedly (idempotent) and safe for a board the parent has already customized.
    @discardableResult
    func mergeStarterVocabulary() -> StarterMergeResult {
        var added = 0
        var skipped = 0
        let existingLabels = Set(words.map { $0.label.lowercased() })
        var nextPos = nextPosition()
        for var word in StarterVocabulary.words {
            if existingLabels.contains(word.label.lowercased()) {
                skipped += 1
                continue
            }
            word.position = nextPos
            nextPos += 1
            words.append(word)
            added += 1
        }
        return StarterMergeResult(wordsAdded: added, wordsSkipped: skipped)
    }
}
