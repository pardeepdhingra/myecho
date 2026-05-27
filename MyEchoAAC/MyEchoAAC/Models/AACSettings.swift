import Foundation

struct AACSettings: Codable, Equatable {
    var gridColumns: Int
    var voiceIdentifier: String?
    var speechRate: Float
    var pitchMultiplier: Float
    var showCategoryFilter: Bool

    static let `default` = AACSettings(
        gridColumns: 4,
        voiceIdentifier: nil,
        speechRate: 0.43,
        pitchMultiplier: 1.03,
        showCategoryFilter: true
    )
}
