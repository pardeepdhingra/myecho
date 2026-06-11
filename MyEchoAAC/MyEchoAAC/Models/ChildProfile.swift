import Foundation

struct ChildProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var emoji: String
    var isDefault: Bool

    init(id: UUID = UUID(), name: String, emoji: String, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.isDefault = isDefault
    }
}
