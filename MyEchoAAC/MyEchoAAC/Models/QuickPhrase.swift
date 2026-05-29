import Foundation

enum QuickPhraseMode: String, Codable, Equatable, CaseIterable {
    case speak
    case startSentence
    case regulation

    var label: String {
        switch self {
        case .speak: "Speak immediately"
        case .startSentence: "Add to message bar"
        case .regulation: "Pinned regulation button"
        }
    }
}

enum RegulationKind: String, Codable, Equatable, CaseIterable {
    case calm
    case help
    case stop

    var systemImage: String {
        switch self {
        case .calm: "leaf.fill"
        case .help: "questionmark.bubble.fill"
        case .stop: "hand.raised.fill"
        }
    }

    var tint: String {
        switch self {
        case .calm: "teal"
        case .help: "yellow"
        case .stop: "red"
        }
    }
}

struct QuickPhrase: Identifiable, Codable, Equatable {
    var id: UUID
    var text: String
    var position: Int
    var mode: QuickPhraseMode
    var sourcePackId: String?
    var regulationKind: RegulationKind?

    enum CodingKeys: String, CodingKey {
        case id, text, position, mode, sourcePackId, regulationKind
    }

    init(id: UUID = UUID(), text: String, position: Int, mode: QuickPhraseMode = .speak, sourcePackId: String? = nil, regulationKind: RegulationKind? = nil) {
        self.id = id
        self.text = text
        self.position = position
        self.mode = mode
        self.sourcePackId = sourcePackId
        self.regulationKind = regulationKind
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        position = try c.decode(Int.self, forKey: .position)
        mode = try c.decodeIfPresent(QuickPhraseMode.self, forKey: .mode) ?? .speak
        sourcePackId = try c.decodeIfPresent(String.self, forKey: .sourcePackId)
        regulationKind = try c.decodeIfPresent(RegulationKind.self, forKey: .regulationKind)
    }
}
