import Foundation

/// The built-in starter vocabulary for the folder ("Motor Plan") board.
///
/// Organized the way a speech therapist recommended (TD Snap style): a small set of high-frequency
/// **Core** words on the home page, plus a wide range of category **folders**. Every word is pre-tagged
/// with a `PartOfSpeech` (so the Fitzgerald-Key colour mode is correct out of the box) and its
/// `colorName` mirrors that word type (so per-word colour mode also looks right). Positions are assigned
/// in authoring order so a word's location stays stable as the board grows.
///
/// Labels are unique across the whole set so the idempotent, skip-duplicates merge
/// (`AACStore.mergeStarterVocabulary`) never produces duplicates for existing users.
enum StarterVocabulary {
    /// Folder display order on the home page is driven by first appearance here.
    static let words: [AACWord] = build()

    /// (label, emoji symbol, optional pronunciation phrase, part of speech)
    private typealias Entry = (label: String, symbol: String, phrase: String?, pos: PartOfSpeech)

    /// Bundled picture-symbol asset name for a starter word (matches the `sym_…` assets). The tile only
    /// uses it if the asset is actually bundled (`SymbolLibrary.exists`), else it falls back to the emoji.
    private static func symbolName(for label: String) -> String {
        "sym_" + label.lowercased().replacingOccurrences(of: " ", with: "_")
    }

    private static func build() -> [AACWord] {
        var result: [AACWord] = []
        var position = 1

        func add(_ category: String, _ entries: [Entry]) {
            for entry in entries {
                result.append(
                    AACWord(
                        label: entry.label,
                        phrase: entry.phrase,
                        symbol: entry.symbol,
                        category: category,
                        colorName: entry.pos.defaultColor,
                        position: position,
                        partOfSpeech: entry.pos,
                        symbolName: Self.symbolName(for: entry.label)
                    )
                )
                position += 1
            }
        }

        // Convenience for folders where every word shares one part of speech.
        func add(_ category: String, _ pos: PartOfSpeech, _ items: [(String, String, String?)]) {
            add(category, items.map { (label: $0.0, symbol: $0.1, phrase: $0.2, pos: pos) })
        }

        // MARK: Core (persistent band) — the 10 highest-frequency "power" words. Kept to ≈ one core
        // band (coreColumns × rows) so it always fits; the rest live in folders below.
        add(AACWord.coreCategory, [
            (label: "I", symbol: "👤", phrase: nil, pos: .pronoun),
            (label: "you", symbol: "🫵", phrase: nil, pos: .pronoun),
            (label: "it", symbol: "👉", phrase: nil, pos: .pronoun),
            (label: "my", symbol: "✋", phrase: nil, pos: .pronoun),
            (label: "want", symbol: "🤲", phrase: nil, pos: .verb),
            (label: "go", symbol: "➡️", phrase: nil, pos: .verb),
            (label: "stop", symbol: "🛑", phrase: nil, pos: .verb),
            (label: "help", symbol: "🫶", phrase: nil, pos: .verb),
            (label: "like", symbol: "💛", phrase: "lyke", pos: .verb),
            (label: "more", symbol: "➕", phrase: nil, pos: .adjective)
        ])

        // MARK: People (nouns + one pronoun).
        add("People", [
            (label: "mum", symbol: "👩", phrase: "mumm", pos: .noun),
            (label: "dad", symbol: "👨", phrase: "dadd", pos: .noun),
            (label: "me", symbol: "🙋", phrase: nil, pos: .pronoun),
            (label: "sister", symbol: "👧", phrase: nil, pos: .noun),
            (label: "brother", symbol: "👦", phrase: nil, pos: .noun),
            (label: "grandma", symbol: "👵", phrase: nil, pos: .noun),
            (label: "grandpa", symbol: "👴", phrase: nil, pos: .noun),
            (label: "teacher", symbol: "🧑‍🏫", phrase: nil, pos: .noun),
            (label: "friend", symbol: "🧒", phrase: nil, pos: .noun),
            (label: "baby", symbol: "👶", phrase: nil, pos: .noun)
        ])

        // MARK: Food (nouns).
        add("Food", .noun, [
            ("apple", "🍎", nil), ("banana", "🍌", nil), ("bread", "🍞", nil),
            ("rice", "🍚", nil), ("snack", "🍪", nil), ("cracker", "🥨", nil),
            ("cheese", "🧀", nil), ("egg", "🥚", nil), ("pasta", "🍝", nil),
            ("biscuit", "🍪", "biskit")
        ])

        // MARK: Drink (nouns).
        add("Drink", .noun, [
            ("water", "💧", "wor ter"), ("milk", "🥛", nil), ("juice", "🧃", "joos"),
            ("tea", "🍵", nil), ("smoothie", "🥤", "smoo thee")
        ])

        // MARK: Actions (verbs).
        add("Actions", .verb, [
            ("eat", "🍽️", nil), ("drink", "🥤", nil), ("play", "🧸", nil),
            ("run", "🏃", nil), ("jump", "🦘", nil), ("sit", "🪑", nil),
            ("open", "📂", nil), ("read", "📖", "reed"), ("sleep", "😴", nil),
            ("wash", "🧼", nil), ("throw", "🤾", "throh"), ("build", "🧱", "bild"),
            ("look", "👀", nil), ("make", "🔨", nil), ("put", "📥", nil),
            ("give", "🎁", nil), ("do", "⚙️", nil), ("turn", "🔄", nil),
            ("can", "💪", nil)
        ])

        // MARK: Describing words (adjectives).
        add("Describing", .adjective, [
            ("big", "🐘", nil), ("little", "🐜", nil), ("hot", "🔥", nil),
            ("cold", "🧊", nil), ("fast", "🏎️", nil), ("slow", "🐌", nil),
            ("good", "👍", nil), ("bad", "👎", nil), ("dirty", "🦠", nil),
            ("clean", "✨", nil), ("loud", "🔊", nil), ("quiet", "🤫", "kwy et"),
            ("hard", "🧱", nil), ("soft", "🧸", nil), ("yummy", "😋", nil),
            ("yucky", "🤢", nil), ("again", "🔁", nil), ("done", "✅", "dun")
        ])

        // MARK: Feelings (adjectives).
        add("Feelings", .adjective, [
            ("happy", "😊", nil), ("sad", "😢", nil), ("angry", "😠", nil),
            ("scared", "😨", nil), ("tired", "😴", nil), ("hurt", "🤕", nil),
            ("sick", "🤒", nil), ("excited", "🤩", "ek sy ted"), ("calm", "😌", "carm")
        ])

        // MARK: Body (nouns).
        add("Body", .noun, [
            ("head", "🙂", nil), ("hand", "✋", nil), ("foot", "🦶", nil),
            ("tummy", "🫃", nil), ("eyes", "👀", nil), ("ears", "👂", nil),
            ("mouth", "👄", nil), ("nose", "👃", nil), ("hair", "💇", nil),
            ("leg", "🦵", nil), ("arm", "💪", nil)
        ])

        // MARK: Places (nouns).
        add("Places", .noun, [
            ("home", "🏠", nil), ("school", "🏫", "skool"), ("park", "🏞️", nil),
            ("shop", "🏬", nil), ("toilet", "🚽", "toy lit"), ("outside", "🌳", nil),
            ("car", "🚗", nil), ("bed", "🛏️", nil)
        ])

        // MARK: Play & toys (nouns).
        add("Play", .noun, [
            ("ball", "⚽", nil), ("book", "📖", nil), ("blocks", "🧱", nil),
            ("bubbles", "🫧", nil), ("doll", "🪆", nil), ("puzzle", "🧩", "puz ul"),
            ("music", "🎵", nil), ("swing", "🎠", nil), ("slide", "🛝", nil)
        ])

        // MARK: School (mixed nouns + verbs).
        add("School", [
            (label: "pencil", symbol: "✏️", phrase: nil, pos: .noun),
            (label: "paper", symbol: "📄", phrase: nil, pos: .noun),
            (label: "glue", symbol: "🧴", phrase: nil, pos: .noun),
            (label: "scissors", symbol: "✂️", phrase: "siz ors", pos: .noun),
            (label: "listen", symbol: "👂", phrase: nil, pos: .verb),
            (label: "finished", symbol: "🏁", phrase: nil, pos: .adjective)
        ])

        // MARK: Clothes (nouns).
        add("Clothes", .noun, [
            ("shirt", "👕", nil), ("pants", "👖", nil), ("shoes", "👟", nil),
            ("socks", "🧦", nil), ("jacket", "🧥", nil), ("hat", "🧢", nil)
        ])

        // MARK: Social (social words).
        add("Social", .social, [
            ("yes", "👍", nil), ("no", "✋", nil),
            ("hello", "👋", nil), ("bye", "👋", nil), ("please", "🙏", "pleez"),
            ("thank you", "🙏", nil), ("sorry", "😟", nil), ("my turn", "🙋", nil),
            ("your turn", "🫵", nil)
        ])

        // MARK: Questions (question words).
        add("Questions", .question, [
            ("what", "❓", nil), ("where", "📍", nil), ("who", "🧑", "hoo"),
            ("when", "⏰", nil), ("why", "🤔", nil), ("how", "🔧", nil)
        ])

        // MARK: Joining words (grammar / function words).
        add("Joining words", .joiningWord, [
            ("not", "🚫", nil),
            ("and", "➕", nil), ("but", "🔀", nil), ("in", "📥", nil),
            ("on", "🔛", nil), ("off", "🔚", nil), ("up", "⬆️", nil),
            ("to", "➡️", "too"), ("with", "🤝", nil), ("the", "🔤", "thuh"),
            ("a", "🅰️", "uh")
        ])

        applyWordForms(to: &result)
        return result
    }

    // MARK: - Word forms seeding

    /// Pre-populated word forms for high-frequency starter words. Parents can always add/edit these
    /// in the word editor. Only verbs and irregular nouns need entries — regular nouns rarely change
    /// in AAC use. Verbs listed as [present-participle, simple-past, third-person-singular].
    private static let seedForms: [String: [String]] = [
        // Core verbs
        "want": ["wanting", "wanted", "wants"],
        "go":   ["going", "went", "goes"],
        "stop": ["stopping", "stopped", "stops"],
        "help": ["helping", "helped", "helps"],
        "like": ["liking", "liked", "likes"],
        // Actions folder verbs
        "eat":   ["eating", "ate", "eats"],
        "drink": ["drinking", "drank", "drinks"],
        "play":  ["playing", "played", "plays"],
        "run":   ["running", "ran", "runs"],
        "jump":  ["jumping", "jumped", "jumps"],
        "sit":   ["sitting", "sat", "sits"],
        "open":  ["opening", "opened", "opens"],
        "sleep": ["sleeping", "slept", "sleeps"],
        "wash":  ["washing", "washed", "washes"],
        "throw": ["throwing", "threw", "throws"],
        "build": ["building", "built", "builds"],
        "look":  ["looking", "looked", "looks"],
        "make":  ["making", "made", "makes"],
        "give":  ["giving", "gave", "gives"],
        "do":    ["doing", "did", "does"],
        "turn":  ["turning", "turned", "turns"],
        // School verbs
        "listen": ["listening", "listened", "listens"],
        // Irregular nouns
        "foot": ["feet"],
        "book": ["books"],
        "ball": ["balls"],
        "hand": ["hands"],
        "friend": ["friends"],
    ]

    private static func applyWordForms(to words: inout [AACWord]) {
        for index in words.indices {
            let label = words[index].label
            if let forms = seedForms[label], !forms.isEmpty {
                words[index].wordForms = forms
            }
        }
    }
}
