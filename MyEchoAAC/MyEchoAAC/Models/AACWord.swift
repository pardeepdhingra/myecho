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

    enum CodingKeys: String, CodingKey {
        case id, label, phrase, symbol, category, colorName, position, isVisible, imagePath, isFavorite, sourcePackId, favoritePosition
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
        favoritePosition: Int? = nil
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
