import Foundation

enum QuickPhraseMode: String, Codable, Equatable, CaseIterable {
    case speak
    case startSentence

    var label: String {
        switch self {
        case .speak: "Speak immediately"
        case .startSentence: "Add to message bar"
        }
    }
}

struct QuickPhrase: Identifiable, Codable, Equatable {
    var id: UUID
    var text: String
    var position: Int
    var mode: QuickPhraseMode
    var sourcePackId: String?

    enum CodingKeys: String, CodingKey {
        case id, text, position, mode, sourcePackId
    }

    init(id: UUID = UUID(), text: String, position: Int, mode: QuickPhraseMode = .speak, sourcePackId: String? = nil) {
        self.id = id
        self.text = text
        self.position = position
        self.mode = mode
        self.sourcePackId = sourcePackId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        position = try c.decode(Int.self, forKey: .position)
        mode = try c.decodeIfPresent(QuickPhraseMode.self, forKey: .mode) ?? .speak
        sourcePackId = try c.decodeIfPresent(String.self, forKey: .sourcePackId)
    }
}
