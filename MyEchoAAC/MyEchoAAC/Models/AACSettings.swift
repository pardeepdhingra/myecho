import Foundation
import UIKit

/// How tiles get their colour.
/// - `byCategory`: every tile in a category shares the category's colour (the long-standing default).
/// - `perWord`: each tile uses its own `colorName`.
/// - `byWordType`: tiles colour by grammatical word type (Fitzgerald Key) — speech-therapist option.
enum ColorMode: String, CaseIterable, Codable, Identifiable {
    case byCategory
    case perWord
    case byWordType

    var id: String { rawValue }

    var label: String {
        switch self {
        case .byCategory: "By category"
        case .perWord: "Per word"
        case .byWordType: "By word type"
        }
    }
}

/// How the kid board is laid out / navigated.
/// - `folders`: TD-Snap-style "Motor Plan" — home page of core words + folder tiles, each folder a
///   fixed, non-scrolling grid so every word keeps one consistent location (muscle memory).
/// - `classic`: the original scrollable grid with a category-chip filter (kept as a fallback).
enum BoardMode: String, CaseIterable, Codable, Identifiable {
    case folders
    case classic

    var id: String { rawValue }

    var label: String {
        switch self {
        case .folders: "Folders (Motor Plan)"
        case .classic: "Classic scroll"
        }
    }
}

/// How a tile is drawn.
/// - `outlined`: near-white fill + a thick word-type/category-coloured border (the TD Snap look).
/// - `filled`: the original soft pastel gradient fill.
enum TileStyle: String, CaseIterable, Codable, Identifiable {
    case outlined
    case filled

    var id: String { rawValue }

    var label: String {
        switch self {
        case .outlined: "Outlined (Motor Plan)"
        case .filled: "Filled"
        }
    }
}

/// Named fixed board sizes (à la TD Snap Motor Plan 30 / 40 / 66). Each is a fixed `columns × rows`
/// grid that fills the screen with no scrolling; overflow paginates. `custom` uses `gridColumns` /
/// `gridRows` from settings. Sizes are landscape-oriented (the primary AAC posture).
enum GridPreset: String, CaseIterable, Codable, Identifiable {
    case size30
    case size40
    case size66
    case custom

    var id: String { rawValue }

    /// (columns, rows). `custom` returns nil — the caller reads `gridColumns`/`gridRows`.
    var dimensions: (columns: Int, rows: Int)? {
        switch self {
        case .size30: (6, 5)
        case .size40: (8, 5)
        case .size66: (11, 6)
        case .custom: nil
        }
    }

    var label: String {
        switch self {
        case .size30: "Big buttons"
        case .size40: "Medium buttons"
        case .size66: "Small buttons (more words)"
        case .custom: "Custom"
        }
    }
}

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
    /// How tiles get their colour (by category / per word / by word type). Replaces the older
    /// `colorTilesByCategory` boolean; legacy boards migrate on decode (true → `.byCategory`,
    /// false → `.perWord`).
    var colorMode: ColorMode
    /// Parent-customized per-category colors + icons. Categories without an entry fall back to
    /// `CategoryDefaults`. Stored here so it persists, exports, and cloud-syncs with the rest of the board.
    var categoryStyles: [CategoryStyle]
    /// When true, filtering to a category keeps every button in the exact grid slot it occupies in
    /// the "All" view (non-matching cells become blank placeholders) so buttons never move — easier
    /// motor planning for kids. Opt-in; only affects real categories (not All/Recent/Favorites).
    /// Used by the **classic** board mode.
    var freezeButtonPositions: Bool
    /// How the kid board is laid out / navigated (folder "Motor Plan" board vs. classic scroll board).
    var boardMode: BoardMode
    /// How tiles are drawn (outlined "Motor Plan" look vs. filled).
    var tileStyle: TileStyle
    /// Named board size (Motor Plan 30/40/66) used by the folder board's fixed, no-scroll grid.
    var gridPreset: GridPreset
    /// Row count used when `gridPreset == .custom` (presets carry their own rows).
    var gridRows: Int
    /// Leftmost columns reserved for the persistent core in the folder board (0–4).
    var coreColumns: Int
    /// Explicit folder (category) order on the folder board's home page. Empty = first-appearance order.
    var categoryOrder: [String]
    /// Folders (categories) the parent has hidden — they don't show on the kid board but their words are
    /// kept (re-show by un-hiding). Independent of per-word visibility.
    var hiddenCategories: [String]
    /// Show the next-word suggestion strip in kid mode (learned from the child's own tap patterns).
    /// Some learners find prediction distracting, so parents can turn it off.
    var showWordSuggestions: Bool
    /// Show a ⌨️ Keyboard tile on the home fringe so literate users can type words directly.
    var showKeyboardPage: Bool
    /// Enable switch-scanning mode — highlights rows then cells; users activate with a tap.
    var scanningEnabled: Bool
    /// Seconds between automatic scan advances (auto-scan mode). 0 = manual only.
    var scanIntervalSeconds: Double

    /// Back-compat convenience for the old boolean meaning ("tiles share their category colour").
    var colorTilesByCategory: Bool { colorMode == .byCategory }

    /// Resolved (columns, rows) for the folder board, honouring the preset or the custom values.
    var resolvedGrid: (columns: Int, rows: Int) {
        if let dims = gridPreset.dimensions { return dims }
        return (max(2, gridColumns), max(2, gridRows))
    }

    /// Largest number of columns that may be reserved for the core band.
    static let maxCoreColumns = 4

    /// Core column count clamped to a sane range and to leave at least one fringe column.
    func resolvedCoreColumns() -> Int {
        let cols = resolvedGrid.columns
        return max(0, min(coreColumns, max(0, cols - 1), Self.maxCoreColumns))
    }

    /// True if this folder (category) is hidden from the kid board.
    func isCategoryHidden(_ name: String) -> Bool {
        hiddenCategories.contains { $0.caseInsensitiveCompare(name) == .orderedSame }
    }

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
        colorMode: .byCategory,
        categoryStyles: [],
        freezeButtonPositions: false,
        boardMode: .folders,
        tileStyle: .outlined,
        gridPreset: .size40,
        gridRows: 5,
        coreColumns: 2,
        categoryOrder: [],
        hiddenCategories: [],
        showWordSuggestions: true,
        showKeyboardPage: true,
        scanningEnabled: false,
        scanIntervalSeconds: 2.0
    )

    enum CodingKeys: String, CodingKey {
        case gridColumns, voiceIdentifier, speechRate, pitchMultiplier
        case showCategoryFilter, showQuickPhrases, trackUsageHistory
        case showSymbolsInMessageBar
        case showAllVoiceQualities, tileScale, showRegulationBar
        case colorMode, categoryStyles
        case freezeButtonPositions
        case boardMode
        case tileStyle, gridPreset, gridRows, coreColumns, categoryOrder, hiddenCategories
        case showWordSuggestions
        case showKeyboardPage
        case scanningEnabled
        case scanIntervalSeconds
        /// Legacy key (pre-`colorMode`); read-only for migration.
        case colorTilesByCategory
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
        colorMode: ColorMode = .byCategory,
        categoryStyles: [CategoryStyle] = [],
        freezeButtonPositions: Bool = false,
        boardMode: BoardMode = .folders,
        tileStyle: TileStyle = .outlined,
        gridPreset: GridPreset = .size40,
        gridRows: Int = 5,
        coreColumns: Int = 2,
        categoryOrder: [String] = [],
        hiddenCategories: [String] = [],
        showWordSuggestions: Bool = true,
        showKeyboardPage: Bool = true,
        scanningEnabled: Bool = false,
        scanIntervalSeconds: Double = 2.0
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
        self.colorMode = colorMode
        self.categoryStyles = categoryStyles
        self.freezeButtonPositions = freezeButtonPositions
        self.boardMode = boardMode
        self.tileStyle = tileStyle
        self.gridPreset = gridPreset
        self.gridRows = gridRows
        self.coreColumns = coreColumns
        self.categoryOrder = categoryOrder
        self.hiddenCategories = hiddenCategories
        self.showWordSuggestions = showWordSuggestions
        self.showKeyboardPage = showKeyboardPage
        self.scanningEnabled = scanningEnabled
        self.scanIntervalSeconds = scanIntervalSeconds
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
        // colorMode supersedes the legacy `colorTilesByCategory` bool. Migrate if only the old key is present.
        if let mode = try c.decodeIfPresent(ColorMode.self, forKey: .colorMode) {
            colorMode = mode
        } else if let legacy = try c.decodeIfPresent(Bool.self, forKey: .colorTilesByCategory) {
            colorMode = legacy ? .byCategory : .perWord
        } else {
            colorMode = .byCategory
        }
        categoryStyles = try c.decodeIfPresent([CategoryStyle].self, forKey: .categoryStyles) ?? []
        freezeButtonPositions = try c.decodeIfPresent(Bool.self, forKey: .freezeButtonPositions) ?? false
        boardMode = try c.decodeIfPresent(BoardMode.self, forKey: .boardMode) ?? .folders
        tileStyle = try c.decodeIfPresent(TileStyle.self, forKey: .tileStyle) ?? .outlined
        gridPreset = try c.decodeIfPresent(GridPreset.self, forKey: .gridPreset) ?? .size40
        gridRows = try c.decodeIfPresent(Int.self, forKey: .gridRows) ?? 5
        coreColumns = try c.decodeIfPresent(Int.self, forKey: .coreColumns) ?? 2
        categoryOrder = try c.decodeIfPresent([String].self, forKey: .categoryOrder) ?? []
        hiddenCategories = try c.decodeIfPresent([String].self, forKey: .hiddenCategories) ?? []
        showWordSuggestions = try c.decodeIfPresent(Bool.self, forKey: .showWordSuggestions) ?? true
        showKeyboardPage = try c.decodeIfPresent(Bool.self, forKey: .showKeyboardPage) ?? true
        scanningEnabled = try c.decodeIfPresent(Bool.self, forKey: .scanningEnabled) ?? false
        scanIntervalSeconds = try c.decodeIfPresent(Double.self, forKey: .scanIntervalSeconds) ?? 2.0
    }

    /// Explicit encode so we write only real stored fields — never the legacy `colorTilesByCategory`
    /// key (which is now a read-only computed property kept solely for back-compat migration).
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(gridColumns, forKey: .gridColumns)
        try c.encodeIfPresent(voiceIdentifier, forKey: .voiceIdentifier)
        try c.encode(speechRate, forKey: .speechRate)
        try c.encode(pitchMultiplier, forKey: .pitchMultiplier)
        try c.encode(showCategoryFilter, forKey: .showCategoryFilter)
        try c.encode(showQuickPhrases, forKey: .showQuickPhrases)
        try c.encode(trackUsageHistory, forKey: .trackUsageHistory)
        try c.encode(showSymbolsInMessageBar, forKey: .showSymbolsInMessageBar)
        try c.encode(showAllVoiceQualities, forKey: .showAllVoiceQualities)
        try c.encode(tileScale, forKey: .tileScale)
        try c.encode(showRegulationBar, forKey: .showRegulationBar)
        try c.encode(colorMode, forKey: .colorMode)
        try c.encode(categoryStyles, forKey: .categoryStyles)
        try c.encode(freezeButtonPositions, forKey: .freezeButtonPositions)
        try c.encode(boardMode, forKey: .boardMode)
        try c.encode(tileStyle, forKey: .tileStyle)
        try c.encode(gridPreset, forKey: .gridPreset)
        try c.encode(gridRows, forKey: .gridRows)
        try c.encode(coreColumns, forKey: .coreColumns)
        try c.encode(categoryOrder, forKey: .categoryOrder)
        try c.encode(hiddenCategories, forKey: .hiddenCategories)
        try c.encode(showWordSuggestions, forKey: .showWordSuggestions)
        try c.encode(showKeyboardPage, forKey: .showKeyboardPage)
        try c.encode(scanningEnabled, forKey: .scanningEnabled)
        try c.encode(scanIntervalSeconds, forKey: .scanIntervalSeconds)
    }
}
