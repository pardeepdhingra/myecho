import SwiftUI

struct AACWord: Identifiable, Codable, Equatable {
    /// Reserved category whose words live on the **home page** of the folder ("Motor Plan") board.
    /// Every other distinct category becomes a folder tile on the home page.
    static let coreCategory = "Core"

    var id: UUID
    var label: String
    var phrase: String
    var symbol: String
    var category: String
    var colorName: TileColorName
    var position: Int
    var isVisible: Bool
    var imagePath: String?
    var isFavorite: Bool
    var sourcePackId: String?
    var favoritePosition: Int?
    var signVideoPath: String?
    var signLanguage: SignLanguage?
    /// Still-frame thumbnail extracted from the sign video by the parent. When set it replaces the
    /// looping video artwork with a static image (lighter weight, instant display).
    var signThumbnailPath: String?
    /// Grammatical word type (Fitzgerald Key). Drives tile colour when the board's colour mode is
    /// `.byWordType`. Optional — untagged words fall back to their `colorName`.
    var partOfSpeech: PartOfSpeech?
    /// Name of a bundled picture-symbol asset (e.g. `sym_apple`). When set and no photo/sign exists,
    /// the tile shows this professional symbol instead of the emoji. A custom **photo always wins**.
    var symbolName: String?
    /// Explicit per-button colour the parent chose for THIS tile. When set it always wins; when nil the
    /// tile follows the board colour mode (by default the **folder's colour**). Lets one button differ
    /// without leaving "colour by folder" for the whole board.
    var colorOverride: TileColorName?
    /// Alternative word forms the parent has configured (e.g. ["eating", "ate", "eats"] for "eat").
    /// Shown as a long-press popover in kid mode so the child can select a grammatical form.
    var wordForms: [String]

    enum CodingKeys: String, CodingKey {
        case id, label, phrase, symbol, category, colorName, position, isVisible, imagePath, isFavorite, sourcePackId, favoritePosition, signVideoPath, signLanguage, signThumbnailPath, partOfSpeech, symbolName, colorOverride, wordForms
    }

    init(
        id: UUID = UUID(),
        label: String,
        phrase: String? = nil,
        symbol: String,
        category: String,
        colorName: TileColorName,
        position: Int,
        isVisible: Bool = true,
        imagePath: String? = nil,
        isFavorite: Bool = false,
        sourcePackId: String? = nil,
        favoritePosition: Int? = nil,
        signVideoPath: String? = nil,
        signLanguage: SignLanguage? = nil,
        signThumbnailPath: String? = nil,
        partOfSpeech: PartOfSpeech? = nil,
        symbolName: String? = nil,
        colorOverride: TileColorName? = nil,
        wordForms: [String] = []
    ) {
        self.id = id
        self.label = label
        self.phrase = phrase ?? label
        self.symbol = symbol
        self.category = category
        self.colorName = colorName
        self.position = position
        self.isVisible = isVisible
        self.imagePath = imagePath
        self.isFavorite = isFavorite
        self.sourcePackId = sourcePackId
        self.favoritePosition = favoritePosition
        self.signVideoPath = signVideoPath
        self.signLanguage = signLanguage
        self.signThumbnailPath = signThumbnailPath
        self.partOfSpeech = partOfSpeech
        self.symbolName = symbolName
        self.colorOverride = colorOverride
        self.wordForms = wordForms
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        label = try c.decode(String.self, forKey: .label)
        phrase = try c.decode(String.self, forKey: .phrase)
        symbol = try c.decode(String.self, forKey: .symbol)
        category = try c.decode(String.self, forKey: .category)
        colorName = try c.decode(TileColorName.self, forKey: .colorName)
        position = try c.decode(Int.self, forKey: .position)
        isVisible = try c.decode(Bool.self, forKey: .isVisible)
        imagePath = try c.decodeIfPresent(String.self, forKey: .imagePath)
        isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        sourcePackId = try c.decodeIfPresent(String.self, forKey: .sourcePackId)
        favoritePosition = try c.decodeIfPresent(Int.self, forKey: .favoritePosition)
        signVideoPath = try c.decodeIfPresent(String.self, forKey: .signVideoPath)
        signLanguage = try c.decodeIfPresent(SignLanguage.self, forKey: .signLanguage)
        signThumbnailPath = try c.decodeIfPresent(String.self, forKey: .signThumbnailPath)
        // Lenient: older/cross-platform boards omit this key → nil (untagged).
        partOfSpeech = try c.decodeIfPresent(PartOfSpeech.self, forKey: .partOfSpeech)
        symbolName = try c.decodeIfPresent(String.self, forKey: .symbolName)
        colorOverride = try c.decodeIfPresent(TileColorName.self, forKey: .colorOverride)
        wordForms = try c.decodeIfPresent([String].self, forKey: .wordForms) ?? []
    }
}

// MARK: - Part of speech (Fitzgerald Key word-type colouring)

/// Grammatical word type used for the speech-therapist-recommended colour coding. Each type maps to
/// a distinct default tile colour so the board is consistent with AAC convention (TD Snap / Fitzgerald
/// Key). Parents can still override per-tile colours by switching the board to per-word colour mode.
enum PartOfSpeech: String, CaseIterable, Codable, Identifiable {
    case noun
    case verb
    case adjective
    case pronoun
    case social
    case question
    case joiningWord

    var id: String { rawValue }

    var label: String {
        switch self {
        case .noun: "Noun (thing)"
        case .verb: "Verb (action)"
        case .adjective: "Describing"
        case .pronoun: "Pronoun"
        case .social: "Social"
        case .question: "Question"
        case .joiningWord: "Joining word"
        }
    }

    /// Fitzgerald-Key-aligned default colour for this word type.
    var defaultColor: TileColorName {
        switch self {
        case .noun: .orange
        case .verb: .green
        case .adjective: .blue
        case .pronoun: .yellow
        case .social: .pink
        case .question: .teal
        case .joiningWord: .purple
        }
    }
}

enum TileColorName: String, CaseIterable, Codable, Identifiable {
    case blue
    case green
    case orange
    case pink
    case purple
    case teal
    case yellow
    case gray
    // Extra hues so many categories can each get a distinct colour (added in the TD Snap quality pass).
    case red
    case indigo
    case brown
    case mint
    case cyan
    case rose
    case coral

    var id: String { rawValue }

    var label: String {
        switch self {
        case .blue: "Blue"
        case .green: "Green"
        case .orange: "Orange"
        case .pink: "Pink"
        case .purple: "Purple"
        case .teal: "Teal"
        case .yellow: "Yellow"
        case .gray: "Gray"
        case .red: "Red"
        case .indigo: "Indigo"
        case .brown: "Brown"
        case .mint: "Mint"
        case .cyan: "Cyan"
        case .rose: "Rose"
        case .coral: "Coral"
        }
    }

    var color: Color {
        switch self {
        case .blue: Color(red: 0.72, green: 0.84, blue: 1.0)
        case .green: Color(red: 0.73, green: 0.91, blue: 0.76)
        case .orange: Color(red: 1.0, green: 0.82, blue: 0.61)
        case .pink: Color(red: 1.0, green: 0.75, blue: 0.84)
        case .purple: Color(red: 0.83, green: 0.78, blue: 1.0)
        case .teal: Color(red: 0.65, green: 0.91, blue: 0.89)
        case .yellow: Color(red: 1.0, green: 0.91, blue: 0.55)
        case .gray: Color(red: 0.86, green: 0.88, blue: 0.91)
        case .red: Color(red: 0.98, green: 0.64, blue: 0.62)
        case .indigo: Color(red: 0.67, green: 0.68, blue: 0.94)
        case .brown: Color(red: 0.82, green: 0.71, blue: 0.58)
        case .mint: Color(red: 0.62, green: 0.93, blue: 0.78)
        case .cyan: Color(red: 0.60, green: 0.85, blue: 0.96)
        case .rose: Color(red: 0.97, green: 0.66, blue: 0.86)
        case .coral: Color(red: 1.0, green: 0.74, blue: 0.62)
        }
    }
}

// MARK: - Category styling (speech-therapist feedback: per-category color + icon)

/// Explicit, parent-customized look for a category. Categories themselves are derived from the
/// `category` string on each `AACWord`; this only carries the *style* (color + icon). When no
/// explicit style exists, `CategoryDefaults` provides a stable, distinct default so every category
/// always has a colour and icon identity. Persisted inside `AACSettings` so it rides the existing
/// local-save / backup / cloud-sync paths with no contract changes.
struct CategoryStyle: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var colorName: TileColorName
    var icon: String

    init(id: UUID = UUID(), name: String, colorName: TileColorName, icon: String) {
        self.id = id
        self.name = name
        self.colorName = colorName
        self.icon = icon
    }
}

/// A category's resolved look — either parent-customized or the deterministic default.
struct ResolvedCategoryStyle: Equatable {
    var colorName: TileColorName
    var icon: String
    var color: Color { colorName.color }
}

enum CategoryDefaults {
    /// Wide palette for auto-assigned category colors so different categories rarely repeat a colour
    /// (gray is reserved for "no strong identity").
    static let palette: [TileColorName] = [
        .blue, .green, .orange, .pink, .purple, .teal, .yellow,
        .red, .indigo, .brown, .mint, .cyan, .rose, .coral
    ]

    /// Distinct default look for the built-in starter categories (each a **different** colour), plus
    /// sensible matches for common custom names. Keyed by a lowercased keyword the category contains.
    /// Order matters — more specific keys first.
    private static let known: [(keyword: String, colorName: TileColorName, icon: String)] = [
        ("core", .gray, "⭐️"),
        ("people", .purple, "👪"),
        ("person", .purple, "👪"),
        ("family", .purple, "👪"),
        ("food", .orange, "🍎"),
        ("drink", .cyan, "🥤"),
        ("action", .green, "🏃"),
        ("describ", .blue, "📏"),
        ("feel", .yellow, "😊"),
        ("body", .rose, "🧍"),
        ("place", .teal, "📍"),
        ("play", .pink, "🧸"),
        ("school", .red, "🏫"),
        ("clothes", .brown, "👕"),
        ("social", .mint, "👋"),
        ("question", .indigo, "❓"),
        ("joining", .coral, "🔤"),
        ("word", .coral, "🔤"),
        // common custom-name fallbacks
        ("home", .blue, "🏠"),
        ("need", .green, "🙋"),
        ("eat", .orange, "🍎"),
        ("toy", .pink, "🧸"),
        ("animal", .mint, "🐶"),
        ("phrase", .indigo, "💬")
    ]

    static func defaultStyle(for name: String) -> ResolvedCategoryStyle {
        let key = name.lowercased()
        if let match = known.first(where: { key.contains($0.keyword) }) {
            return ResolvedCategoryStyle(colorName: match.colorName, icon: match.icon)
        }
        let color = palette[stableIndex(key, modulo: palette.count)]
        return ResolvedCategoryStyle(colorName: color, icon: "🗂️")
    }

    /// Deterministic, hash-stable index (Swift's `Hashable` is per-process randomized, which would make
    /// a category's default color flip between launches — this stays put).
    private static func stableIndex(_ string: String, modulo: Int) -> Int {
        guard modulo > 0 else { return 0 }
        var hash = 5381
        for scalar in string.unicodeScalars {
            hash = (hash &* 33) &+ Int(scalar.value)
        }
        return abs(hash) % modulo
    }
}
