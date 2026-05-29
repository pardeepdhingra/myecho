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
    var useNaturalVoice: Bool
    var naturalVoiceId: String?
    var showAllVoiceQualities: Bool
    var tileScale: Double

    static let `default` = AACSettings(
        gridColumns: 4,
        voiceIdentifier: nil,
        speechRate: 0.43,
        pitchMultiplier: 1.03,
        showCategoryFilter: true,
        showQuickPhrases: true,
        trackUsageHistory: true,
        showSymbolsInMessageBar: true,
        useNaturalVoice: false,
        naturalVoiceId: "EXAVITQu4vr4xnSDxMaL",
        showAllVoiceQualities: false,
        tileScale: 1.0
    )

    enum CodingKeys: String, CodingKey {
        case gridColumns, voiceIdentifier, speechRate, pitchMultiplier
        case showCategoryFilter, showQuickPhrases, trackUsageHistory
        case showSymbolsInMessageBar, useNaturalVoice, naturalVoiceId
        case showAllVoiceQualities, tileScale
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
        useNaturalVoice: Bool = false,
        naturalVoiceId: String? = "EXAVITQu4vr4xnSDxMaL",
        showAllVoiceQualities: Bool = false,
        tileScale: Double = 1.0
    ) {
        self.gridColumns = gridColumns
        self.voiceIdentifier = voiceIdentifier
        self.speechRate = speechRate
        self.pitchMultiplier = pitchMultiplier
        self.showCategoryFilter = showCategoryFilter
        self.showQuickPhrases = showQuickPhrases
        self.trackUsageHistory = trackUsageHistory
        self.showSymbolsInMessageBar = showSymbolsInMessageBar
        self.useNaturalVoice = useNaturalVoice
        self.naturalVoiceId = naturalVoiceId
        self.showAllVoiceQualities = showAllVoiceQualities
        self.tileScale = tileScale
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
        useNaturalVoice = try c.decodeIfPresent(Bool.self, forKey: .useNaturalVoice) ?? false
        naturalVoiceId = try c.decodeIfPresent(String.self, forKey: .naturalVoiceId) ?? "EXAVITQu4vr4xnSDxMaL"
        showAllVoiceQualities = try c.decodeIfPresent(Bool.self, forKey: .showAllVoiceQualities) ?? false
        tileScale = try c.decodeIfPresent(Double.self, forKey: .tileScale) ?? 1.0
    }
}
