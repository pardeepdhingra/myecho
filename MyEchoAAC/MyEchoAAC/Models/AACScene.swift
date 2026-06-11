import Foundation

struct AACSceneHotspot: Codable, Identifiable {
    let id: UUID
    var label: String
    var phrase: String
    var symbol: String
    var normalizedX: Double
    var normalizedY: Double
    var radius: Double

    init(
        id: UUID = UUID(),
        label: String,
        phrase: String,
        symbol: String,
        normalizedX: Double,
        normalizedY: Double,
        radius: Double = 0.09
    ) {
        self.id = id
        self.label = label
        self.phrase = phrase
        self.symbol = symbol
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.radius = radius
    }
}

struct AACScene: Codable, Identifiable {
    let id: UUID
    var name: String
    var imagePath: String?
    var hotspots: [AACSceneHotspot]
    var position: Int
    var isVisible: Bool

    init(
        id: UUID = UUID(),
        name: String,
        imagePath: String? = nil,
        hotspots: [AACSceneHotspot] = [],
        position: Int = 0,
        isVisible: Bool = true
    ) {
        self.id = id
        self.name = name
        self.imagePath = imagePath
        self.hotspots = hotspots
        self.position = position
        self.isVisible = isVisible
    }
}
