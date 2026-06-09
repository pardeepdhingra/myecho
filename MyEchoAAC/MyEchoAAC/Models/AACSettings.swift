import Foundation
import UIKit

struct AACSettings: Codable, Equatable {
    /// Smallest column count the board allows.
    static let minGridColumns = 3
    /// Largest column count, device-aware. iPad (the primary horizontal device) goes up to 12×12 per
    /// speech-therapist feedback; iPhone caps at 6 so tiles stay big enough to tap.
    static var maxGridColumns: Int {
        UIDevice.current.userInterfaceIdiom == .pad ? 12 : 6
    }

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
    /// When true, every tile uses its category's color (the speech-therapist default: cards of a
    /// category share one sample color). When false, each tile uses its own per-word color.
    var colorTilesByCategory: Bool
    /// Parent-customized per-category colors + icons. Categories without an entry fall back to
    /// `CategoryDefaults`. Stored here so it persists, exports, and cloud-syncs with the rest of the board.
    var categoryStyles: [CategoryStyle]
    /// When true, filtering to a category keeps every button in the exact grid slot it occupies in
    /// the "All" view (non-matching cells become blank placeholders) so buttons never move — easier
    /// motor planning for kids. Opt-in; only affects real categories (not All/Recent/Favorites).
    var freezeButtonPositions: Bool

    static let `default` = AACSettings(
        gridColumns: 8,
        voiceIdentifier: nil,
        speechRate: 0.43,
        pitchMultiplier: 1.03,
        showCategoryFilter: true,
        showQuickPhrases: true,
        trackUsageHistory: true,
        showSymbolsInMessageBar: true,
        showAllVoiceQualities: false,
        tileScale: 1.0,
        showRegulationBar: true,
        colorTilesByCategory: true,
        categoryStyles: [],
        freezeButtonPositions: false
    )

    enum CodingKeys: String, CodingKey {
        case gridColumns, voiceIdentifier, speechRate, pitchMultiplier
        case showCategoryFilter, showQuickPhrases, trackUsageHistory
        case showSymbolsInMessageBar
        case showAllVoiceQualities, tileScale, showRegulationBar
        case colorTilesByCategory, categoryStyles
        case freezeButtonPositions
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
        showRegulationBar: Bool = true,
        colorTilesByCategory: Bool = true,
        categoryStyles: [CategoryStyle] = [],
        freezeButtonPositions: Bool = false
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
        self.colorTilesByCategory = colorTilesByCategory
        self.categoryStyles = categoryStyles
        self.freezeButtonPositions = freezeButtonPositions
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
        colorTilesByCategory = try c.decodeIfPresent(Bool.self, forKey: .colorTilesByCategory) ?? true
        categoryStyles = try c.decodeIfPresent([CategoryStyle].self, forKey: .categoryStyles) ?? []
        freezeButtonPositions = try c.decodeIfPresent(Bool.self, forKey: .freezeButtonPositions) ?? false
    }
}
