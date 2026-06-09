import SwiftUI

struct AACWord: Identifiable, Codable, Equatable {
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

    enum CodingKeys: String, CodingKey {
        case id, label, phrase, symbol, category, colorName, position, isVisible, imagePath, isFavorite, sourcePackId, favoritePosition, signVideoPath, signLanguage
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
        signLanguage: SignLanguage? = nil
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
    /// Palette used for auto-assigned category colors (gray is reserved for "no strong identity").
    static let palette: [TileColorName] = [.blue, .green, .orange, .pink, .purple, .teal, .yellow]

    /// Distinct default look for the built-in starter categories, plus sensible matches for common
    /// custom names. Keyed by a lowercased keyword that the category name contains.
    private static let known: [(keyword: String, colorName: TileColorName, icon: String)] = [
        ("home", .blue, "🏠"),
        ("feel", .yellow, "😊"),
        ("need", .green, "🙋"),
        ("play", .pink, "🧸"),
        ("people", .purple, "👪"),
        ("person", .purple, "👪"),
        ("family", .purple, "👪"),
        ("place", .teal, "📍"),
        ("food", .orange, "🍎"),
        ("eat", .orange, "🍎"),
        ("drink", .teal, "🥤"),
        ("school", .orange, "🏫"),
        ("toy", .pink, "🧸"),
        ("animal", .green, "🐶"),
        ("body", .pink, "🧍"),
        ("phrase", .purple, "💬")
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
