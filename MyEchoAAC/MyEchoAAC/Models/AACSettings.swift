import Foundation

struct AACSettings: Codable, Equatable {
    var gridColumns: Int
    var voiceIdentifier: String?
    var speechRate: Float
    var pitchMultiplier: Float
    var showCategoryFilter: Bool
    var showQuickPhrases: Bool
    var trackUsageHistory: Bool
    var showSymbolsInMessageBar: Bool
    var showAllVoiceQualities: Bool
    var tileScale: Double
    var showRegulationBar: Bool

    static let `default` = AACSettings(
        gridColumns: 4,
        voiceIdentifier: nil,
        speechRate: 0.43,
        pitchMultiplier: 1.03,
        showCategoryFilter: true,
        showQuickPhrases: true,
        trackUsageHistory: true,
        showSymbolsInMessageBar: true,
        showAllVoiceQualities: false,
        tileScale: 1.0,
        showRegulationBar: true
    )

    enum CodingKeys: String, CodingKey {
        case gridColumns, voiceIdentifier, speechRate, pitchMultiplier
        case showCategoryFilter, showQuickPhrases, trackUsageHistory
        case showSymbolsInMessageBar
        case showAllVoiceQualities, tileScale, showRegulationBar
    }

    init(
        gridColumns: Int,
        voiceIdentifier: String?,
        speechRate: Float,
        pitchMultiplier: Float,
        showCategoryFilter: Bool,
        showQuickPhrases: Bool = true,
        trackUsageHistory: Bool = true,
        showSymbolsInMessageBar: Bool = true,
        showAllVoiceQualities: Bool = false,
        tileScale: Double = 1.0,
        showRegulationBar: Bool = true
    ) {
        self.gridColumns = gridColumns
        self.voiceIdentifier = voiceIdentifier
        self.speechRate = speechRate
        self.pitchMultiplier = pitchMultiplier
        self.showCategoryFilter = showCategoryFilter
        self.showQuickPhrases = showQuickPhrases
        self.trackUsageHistory = trackUsageHistory
        self.showSymbolsInMessageBar = showSymbolsInMessageBar
        self.showAllVoiceQualities = showAllVoiceQualities
        self.tileScale = tileScale
        self.showRegulationBar = showRegulationBar
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        gridColumns = try c.decode(Int.self, forKey: .gridColumns)
        voiceIdentifier = try c.decodeIfPresent(String.self, forKey: .voiceIdentifier)
        speechRate = try c.decode(Float.self, forKey: .speechRate)
        pitchMultiplier = try c.decode(Float.self, forKey: .pitchMultiplier)
        showCategoryFilter = try c.decode(Bool.self, forKey: .showCategoryFilter)
        showQuickPhrases = try c.decodeIfPresent(Bool.self, forKey: .showQuickPhrases) ?? true
        trackUsageHistory = try c.decodeIfPresent(Bool.self, forKey: .trackUsageHistory) ?? true
        showSymbolsInMessageBar = try c.decodeIfPresent(Bool.self, forKey: .showSymbolsInMessageBar) ?? true
        showAllVoiceQualities = try c.decodeIfPresent(Bool.self, forKey: .showAllVoiceQualities) ?? false
        tileScale = try c.decodeIfPresent(Double.self, forKey: .tileScale) ?? 1.0
        showRegulationBar = try c.decodeIfPresent(Bool.self, forKey: .showRegulationBar) ?? true
    }
}
