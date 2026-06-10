import SwiftUI
import UIKit

/// One cell of the kid board when "Freeze button positions" is active: either a real word tile or a
/// blank placeholder that holds the slot a non-matching word occupies in the "All" layout.
private enum BoardSlot: Identifiable {
    case word(AACWord)
    case blank(Int)

    var id: AnyHashable {
        switch self {
        case .word(let w): return w.id
        case .blank(let i): return "__blank__\(i)"
        }
    }
}

struct KidModeView: View {
    @EnvironmentObject private var store: AACStore
    @EnvironmentObject private var speech: SpeechService
    @EnvironmentObject private var history: UsageHistory

    @StateObject private var composer = MessageComposer()
    @State private var selectedCategory: String?
    /// Folder ("Motor Plan") board navigation: nil = home page, otherwise the open folder's category
    /// (or `favoritesCategoryToken`). Only used when `settings.boardMode == .folders`.
    @State private var openFolder: String?
    /// Current fringe page when a folder/home overflows the fixed grid.
    @State private var fringePage: Int = 0
    @State private var showingParentGate = false
    @State private var showingParentMode = false
    @AppStorage("vani.welcomeSeen") private var welcomeSeen: Bool = false
    @State private var showingWelcome = false
    @State private var showingSentenceHistory = false
    @State private var showingAbout = false

    private var columns: [GridItem] {
        return Array(
            repeating: GridItem(.flexible(minimum: 56), spacing: 10),
            count: max(2, min(store.settings.gridColumns, AACSettings.maxGridColumns))
        )
    }

    private static let recentCategoryToken = "__recent__"
    private static let favoritesCategoryToken = "__favorites__"

    private var categories: [String?] {
        var list: [String?] = [nil]
        if store.words.contains(where: { $0.isFavorite && $0.isVisible }) {
            list.append(Self.favoritesCategoryToken)
        }
        if store.settings.trackUsageHistory && !history.recentWordIds(limit: 1).isEmpty {
            list.append(Self.recentCategoryToken)
        }
        list.append(contentsOf: store.categories.map(Optional.some))
        return list
    }

    private func categoryLabel(_ category: String?) -> String {
        if category == Self.recentCategoryToken { return "Recent" }
        if category == Self.favoritesCategoryToken { return "Favorites" }
        return category ?? "All"
    }

    /// Icon + tint for a category chip. The special "All / Recent / Favorites" buckets get their own
    /// look; real categories use the parent-customized or default style.
    private func categoryChipStyle(_ category: String?) -> (icon: String, tint: Color) {
        guard let name = category else {
            return ("◎", Color.accentColor)
        }
        if name == Self.recentCategoryToken {
            return ("🕒", Color(red: 0.45, green: 0.55, blue: 0.75))
        }
        if name == Self.favoritesCategoryToken {
            return ("⭐️", Color(red: 0.95, green: 0.72, blue: 0.15))
        }
        let style = store.resolvedCategoryStyle(for: name)
        return (style.icon, style.color)
    }

    private func visibleWordsForSelectedCategory() -> [AACWord] {
        if selectedCategory == Self.recentCategoryToken {
            let recentIds = history.recentWordIds(limit: 12)
            let byId = Dictionary(uniqueKeysWithValues: store.words.filter { $0.isVisible }.map { ($0.id, $0) })
            return recentIds.compactMap { byId[$0] }
        }
        if selectedCategory == Self.favoritesCategoryToken {
            return store.favoritesOrdered.filter { $0.isVisible }
        }
        return store.visibleWords(in: selectedCategory)
    }

    /// True when the board should hold buttons in their "All" position for the selected category.
    /// Only applies to real categories — All, Recent, and Favorites keep their normal behavior.
    private var isFreezeActive: Bool {
        guard store.settings.freezeButtonPositions, let selectedCategory else { return false }
        return selectedCategory != Self.recentCategoryToken
            && selectedCategory != Self.favoritesCategoryToken
    }

    /// The full "All" grid with non-matching cells blanked out, so matching tiles keep their exact
    /// slot. Trailing blanks (after the last matching tile) are trimmed to avoid empty rows.
    private func freezeSlotsForSelectedCategory() -> [BoardSlot] {
        guard let category = selectedCategory else { return [] }
        let all = store.visibleWords(in: nil)
        let slots: [BoardSlot] = all.enumerated().map { index, word in
            word.category == category ? .word(word) : .blank(index)
        }
        guard let lastWordIdx = slots.lastIndex(where: {
            if case .word = $0 { return true }
            return false
        }) else { return [] }
        return Array(slots[0...lastWordIdx])
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            if store.settings.boardMode == .folders {
                folderChipStrip
            }
            regulationBar
            quickPhraseStrip
            messageBar
            if store.settings.boardMode == .folders {
                folderBoard
            } else {
                categoryFilter
                wordGrid
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .background(appBackground.ignoresSafeArea())
        .preferredColorScheme(.light)
            .sheet(isPresented: $showingParentGate) {
                PINGateView {
                    showingParentMode = true
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingWelcome, onDismiss: {
                welcomeSeen = true
            }) {
                WelcomeView()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showingSentenceHistory) {
                SentenceHistorySheet { sentence in
                    speech.speak(sentence, settings: store.settings)
                    Haptics.actionTap()
                }
                .environmentObject(history)
                .presentationDetents([.large])
            }
            .fullScreenCover(isPresented: $showingAbout) {
                NavigationStack {
                    AboutView()
                }
            }
            .task {
                if !welcomeSeen {
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    showingWelcome = true
                }
            }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
            .sheet(isPresented: $showingParentMode) {
                ParentModeView()
                    .environmentObject(store)
                    .environmentObject(speech)
                    .environmentObject(history)
                    .presentationDetents([.large])
            }
            .onChange(of: store.words) { _, _ in
                if let selectedCategory, !store.categories.contains(selectedCategory) {
                    self.selectedCategory = nil
                }
                // If the open folder lost all its visible words (deleted/hidden), fall back to home.
                if let openFolder, openFolder != Self.favoritesCategoryToken,
                   !folderCategories.contains(openFolder) {
                    self.openFolder = nil
                }
            }
    }

    private var appBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.99, blue: 1.0),
                Color(red: 0.94, green: 0.99, blue: 0.97),
                Color(red: 1.0, green: 0.98, blue: 0.94)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 56)
                .accessibilityHidden(true)

            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                Text("वाणी")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.85))
                Text("Vani")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.55))
            }

            Button {
                showingAbout = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.75))
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(Color.black.opacity(0.08), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About Vani")

            Button {
                showingParentGate = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.75))
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(Color.black.opacity(0.08), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Parent settings")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white, lineWidth: 1)
        }
    }

    @ViewBuilder
    private func messageChip(for word: AACWord) -> some View {
        HStack(spacing: 8) {
            if store.settings.showSymbolsInMessageBar {
                chipSymbol(for: word)
            }
            Text(word.label)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.85))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(store.tileColor(for: word).opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(word.label)
        .accessibilityIdentifier("chip_\(word.label)")
    }

    @ViewBuilder
    private func chipSymbol(for word: AACWord) -> some View {
        if let filename = word.imagePath, let image = ImageStore.load(filename) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else {
            Text(word.symbol)
                .font(.system(size: 24))
        }
    }

    @ViewBuilder
    private var regulationBar: some View {
        if store.settings.showRegulationBar {
            let buttons = store.quickPhrases
                .filter { $0.mode == .regulation }
                .sorted { ($0.regulationKind?.rawValue ?? "") < ($1.regulationKind?.rawValue ?? "") }
            if !buttons.isEmpty {
                HStack(spacing: 8) {
                    ForEach(buttons) { phrase in
                        Button {
                            Haptics.actionTap()
                            speech.speak(phrase.text, settings: store.settings)
                            history.recordSentence(phrase.text, enabled: store.settings.trackUsageHistory)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: phrase.regulationKind?.systemImage ?? "exclamationmark.circle.fill")
                                    .font(.system(.title3, weight: .bold))
                                Text(phrase.text)
                                    .font(.system(.callout, design: .rounded, weight: .bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(regulationColor(phrase.regulationKind))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(PressableTileStyle())
                        .accessibilityLabel(phrase.text)
                    }
                }
            }
        }
    }

    private func regulationColor(_ kind: RegulationKind?) -> Color {
        switch kind {
        case .calm: Color(red: 0.13, green: 0.66, blue: 0.55)
        case .help: Color(red: 0.95, green: 0.72, blue: 0.15)
        case .stop: Color(red: 0.85, green: 0.27, blue: 0.27)
        case nil: Color.accentColor
        }
    }

    @ViewBuilder
    private var quickPhraseStrip: some View {
        if store.settings.showQuickPhrases {
            let nonRegulation = store.quickPhrases
                .filter { $0.mode != .regulation }
                .sorted { $0.position < $1.position }
            if !nonRegulation.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(nonRegulation) { phrase in
                            Button {
                                handleQuickPhrase(phrase)
                            } label: {
                                HStack(spacing: 6) {
                                    if phrase.mode == .startSentence {
                                        Image(systemName: "text.bubble")
                                            .font(.caption.weight(.bold))
                                    }
                                    Text(phrase.text)
                                        .font(.system(.callout, design: .rounded, weight: .semibold))
                                }
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(phrase.mode == .speak ? Color.accentColor : Color.accentColor.opacity(0.78))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(PressableTileStyle())
                            .accessibilityLabel(phrase.text)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    private var messageBar: some View {
        VStack(spacing: 10) {
            HStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if composer.isEmpty {
                            Text("Ready to talk")
                                .font(.system(.title3, design: .rounded, weight: .medium))
                                .foregroundStyle(Color.black.opacity(0.5))
                                .padding(.horizontal, 4)
                        } else {
                            ForEach(composer.entries) { entry in
                                messageChip(for: entry.word)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 58)
                .accessibilityIdentifier("messageBar")

                Button {
                    speakMessage()
                } label: {
                    Label("Speak", systemImage: "speaker.wave.2.fill")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .frame(width: 54, height: 54)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
                .disabled(composer.isEmpty)
                .accessibilityIdentifier("speakButton")
            }

            HStack(spacing: 10) {
                Button {
                    removeLastWord()
                } label: {
                    Label("Delete", systemImage: "delete.left.fill")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor.opacity(0.85))
                .disabled(composer.isEmpty)
                .accessibilityIdentifier("deleteButton")

                Button {
                    clearMessage()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(Color.accentColor)
                .disabled(composer.isEmpty)
                .accessibilityIdentifier("clearButton")

                Button {
                    showingSentenceHistory = true
                } label: {
                    Label("Recent", systemImage: "clock.arrow.circlepath")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(Color.accentColor)
                .disabled(history.spokenSentences.isEmpty)
            }
            .font(.system(.body, design: .rounded, weight: .semibold))
        }
        .padding(12)
        .background(.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
    }

    @ViewBuilder
    private var categoryFilter: some View {
        if store.settings.showCategoryFilter {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        categoryChip(category)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }

    @ViewBuilder
    private func categoryChip(_ category: String?) -> some View {
        let style = categoryChipStyle(category)
        let isSelected = selectedCategory == category
        Button {
            selectedCategory = category
            Haptics.actionTap()
        } label: {
            HStack(spacing: 6) {
                Text(style.icon)
                    .font(.system(size: 17))
                Text(categoryLabel(category))
                    .font(.system(.callout, design: .rounded, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? style.tint : style.tint.opacity(0.20))
            .foregroundStyle(isSelected ? Color.white : Color.black.opacity(0.82))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? Color.clear : style.tint.opacity(0.55), lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(categoryLabel(category))
    }

    private var wordGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                if isFreezeActive {
                    ForEach(freezeSlotsForSelectedCategory()) { slot in
                        switch slot {
                        case .word(let word): wordTile(word)
                        case .blank: BlankTileView()
                        }
                    }
                } else {
                    ForEach(visibleWordsForSelectedCategory()) { word in
                        wordTile(word)
                    }
                }
            }
            .padding(.bottom, 18)
        }
    }

    // MARK: - Folder ("Motor Plan") board: persistent core + paged fringe, fixed no-scroll grid

    private static let boardSpacing: CGFloat = 8
    private static let favoritesColor = Color(red: 0.95, green: 0.72, blue: 0.15)

    /// One cell of the folder board's fixed grid.
    private enum FringeCell {
        case word(AACWord)
        case blank
        case folder(name: String, icon: String, color: Color)
        case favorites
        case back     // a "Home" tile shown first inside a folder
    }

    /// Core words: the persistent left band, identical on every page, in stable position order.
    private var coreWords: [AACWord] {
        store.words
            .filter { $0.isVisible && $0.category == AACWord.coreCategory }
            .sorted { $0.position < $1.position }
    }

    /// Non-core categories with ≥1 visible word, ordered by the parent's `categoryOrder` first, then by
    /// first appearance. Each becomes a folder tile in the fringe on the home page.
    private var folderCategories: [String] {
        let visible = store.words
            .filter { $0.isVisible && $0.category != AACWord.coreCategory }
            .sorted { $0.position < $1.position }
            .map(\.category)
        let distinct = ((Array(NSOrderedSet(array: visible)) as? [String]) ?? [])
            .filter { !store.settings.isCategoryHidden($0) }
        let order = store.settings.categoryOrder
        guard !order.isEmpty else { return distinct }
        let ordered = order.filter { distinct.contains($0) }
        let rest = distinct.filter { !ordered.contains($0) }
        return ordered + rest
    }

    private var showFavoritesFolder: Bool {
        store.words.contains { $0.isFavorite && $0.isVisible }
    }

    /// A folder's cells: the category's words in fixed position order, hidden words held as blanks so
    /// visible words never shift (muscle memory). Trailing blanks trimmed.
    private func folderSlots(for category: String) -> [BoardSlot] {
        let all = store.words
            .filter { $0.category == category }
            .sorted { $0.position < $1.position }
        let slots: [BoardSlot] = all.enumerated().map { index, word in
            word.isVisible ? .word(word) : .blank(index)
        }
        guard let lastWordIdx = slots.lastIndex(where: {
            if case .word = $0 { return true }
            return false
        }) else { return [] }
        return Array(slots[0...lastWordIdx])
    }

    private func folderTitle(_ folder: String) -> String {
        folder == Self.favoritesCategoryToken ? "Favorites" : folder
    }

    private func open(folder: String?) {
        openFolder = folder
        fringePage = 0
        Haptics.actionTap()
    }

    /// Fringe cells for the current page-set: folder tiles on home, the folder's words inside a folder.
    /// Core words that don't fit the persistent band (small grid / `coreColumns == 0`) spill to the
    /// start of the home fringe so none are ever lost.
    private func currentFringeCells(coreCapacity: Int) -> [FringeCell] {
        guard let folder = openFolder else {
            var cells: [FringeCell] = []
            if coreWords.count > coreCapacity {
                cells.append(contentsOf: coreWords.dropFirst(coreCapacity).map { .word($0) })
            }
            cells.append(contentsOf: folderCategories.map { name in
                let style = store.resolvedCategoryStyle(for: name)
                return FringeCell.folder(name: name, icon: style.icon, color: style.color)
            })
            if showFavoritesFolder { cells.append(.favorites) }
            return cells
        }
        // A "Home" tile leads every folder page — a board-tile back control (always reliable).
        if folder == Self.favoritesCategoryToken {
            return [.back] + store.favoritesOrdered.filter { $0.isVisible }.map { .word($0) }
        }
        return [.back] + folderSlots(for: folder).map { slot in
            switch slot {
            case .word(let w): return .word(w)
            case .blank: return .blank
            }
        }
    }

    private func coreCells(capacity: Int) -> [FringeCell] {
        Array(coreWords.prefix(capacity)).map { .word($0) }
    }

    @ViewBuilder
    private var folderBoard: some View {
        GeometryReader { geo in
            let spacing = Self.boardSpacing
            // Reserve room for the page-dots row so tiles never get clipped at the bottom.
            let dotsReserve: CGFloat = 26
            // The grid size sets the *tile size* (density), not a fixed column count: we then FILL the
            // available space with as many columns/rows as fit at that size. This uses the whole screen
            // (no wasted space) and only paginates when content genuinely exceeds a full screen.
            let baseTile: CGFloat = {
                switch store.settings.gridPreset {
                case .size30: return 116   // big buttons
                case .size40: return 90    // medium
                case .size66: return 70    // small buttons, more words
                case .custom: return max(56, 980 / CGFloat(max(3, store.settings.gridColumns)))
                }
            }()
            let targetTile = baseTile * CGFloat(min(max(store.settings.tileScale, 0.7), 1.6))
            let cols = max(3, Int((geo.size.width + spacing) / (targetTile + spacing)))
            let rows = max(2, Int((geo.size.height - dotsReserve + spacing) / (targetTile + spacing)))
            // Core band: keep ≥2 fringe columns, but widen it (within limits) so it can hold ALL the
            // core words at the current row count — otherwise overflow core words would only show on
            // the home page and vanish inside folders (the "fixed buttons get overridden" bug).
            let baseCore = max(0, min(store.settings.coreColumns, cols - 2, AACSettings.maxCoreColumns))
            let neededForCore = rows > 0 ? Int(ceil(Double(coreWords.count) / Double(rows))) : 0
            let coreCols = baseCore == 0 ? 0 : max(baseCore, min(neededForCore, cols - 2, AACSettings.maxCoreColumns))
            let fringeCols = max(1, cols - coreCols)
            let bandGap: CGFloat = coreCols > 0 ? spacing * 2 : 0
            let availW = geo.size.width - spacing * CGFloat(cols - 1) - bandGap
            let availH = geo.size.height - dotsReserve - spacing * CGFloat(rows - 1)
            // Exact fit (no floor) so the grid is always fully on-screen.
            let tile = min(availW / CGFloat(cols), availH / CGFloat(rows))
            let scale = min(max(tile / 110.0, 0.7), 1.8)
            let gridH = CGFloat(rows) * tile + CGFloat(rows - 1) * spacing

            HStack(alignment: .top, spacing: bandGap) {
                if coreCols > 0 {
                    fixedGrid(coreCells(capacity: coreCols * rows),
                              cols: coreCols, rows: rows, tile: tile, scale: scale)
                }
                fringePager(cols: fringeCols, rows: rows, tile: tile, scale: scale,
                            gridHeight: gridH, coreCapacity: coreCols * rows)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    /// A horizontal strip of folder shortcuts shown on top of the board (categories "on top"), so a
    /// folder can be opened from anywhere. The current location is highlighted.
    private var folderChipStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                folderChip(title: "Home", icon: "🏠", color: Color.accentColor, isSelected: openFolder == nil) {
                    open(folder: nil)
                }
                ForEach(folderCategories, id: \.self) { name in
                    let style = store.resolvedCategoryStyle(for: name)
                    folderChip(title: name, icon: style.icon, color: style.color, isSelected: openFolder == name) {
                        open(folder: name)
                    }
                }
                if showFavoritesFolder {
                    folderChip(title: "Favorites", icon: "⭐️", color: Self.favoritesColor,
                               isSelected: openFolder == Self.favoritesCategoryToken) {
                        open(folder: Self.favoritesCategoryToken)
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
    }

    private func folderChip(title: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(icon).font(.system(size: 16))
                Text(title)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.18))
            .foregroundStyle(isSelected ? Color.white : Color.black.opacity(0.82))
            .clipShape(Capsule())
            .overlay { Capsule().stroke(isSelected ? Color.clear : color.opacity(0.5), lineWidth: 1.5) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    /// A breadcrumb showing the current location. Navigation back to home is done with the in-board
    /// "Home" tile (the first cell of a folder), which reliably receives taps.
    private var folderNavBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "house.fill")
                .font(.footnote.weight(.bold))
                .foregroundStyle(openFolder == nil ? Color.accentColor : Color.black.opacity(0.55))
            Text("Home")
                .font(.system(.callout, design: .rounded, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.7))
            if let folder = openFolder {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(store.resolvedCategoryStyle(for: folder).icon)
                Text(folderTitle(folder))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer()
        }
    }

    /// The fringe region. Never scrolls — overflow spills onto pages flipped with prev/next + dots.
    /// (Uses an explicit page index rather than a paged `TabView`, whose gesture layer can swallow
    /// taps on the folder/word buttons inside it.)
    private func fringePager(cols: Int, rows: Int, tile: CGFloat, scale: Double, gridHeight: CGFloat, coreCapacity: Int) -> some View {
        let capacity = max(1, cols * rows)
        let cells = currentFringeCells(coreCapacity: coreCapacity)
        let pages: [[FringeCell]] = cells.isEmpty
            ? [[]]
            : stride(from: 0, to: cells.count, by: capacity).map {
                Array(cells[$0 ..< min($0 + capacity, cells.count)])
            }
        let page = min(max(fringePage, 0), pages.count - 1)
        let width = CGFloat(cols) * tile + CGFloat(cols - 1) * Self.boardSpacing
        return VStack(spacing: 6) {
            fixedGrid(pages[page], cols: cols, rows: rows, tile: tile, scale: scale)
            if pages.count > 1 {
                HStack(spacing: 10) {
                    Button { fringePage = max(0, page - 1) } label: {
                        Image(systemName: "chevron.left.circle.fill")
                    }
                    .disabled(page == 0)
                    .accessibilityLabel("Previous page")

                    ForEach(0 ..< pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == page ? Color.accentColor : Color.black.opacity(0.18))
                            .frame(width: 8, height: 8)
                    }

                    Button { fringePage = min(pages.count - 1, page + 1) } label: {
                        Image(systemName: "chevron.right.circle.fill")
                    }
                    .disabled(page == pages.count - 1)
                    .accessibilityLabel("Next page")
                }
                .font(.title3)
                .tint(Color.accentColor)
            }
        }
        .frame(width: width, alignment: .topLeading)
    }

    /// Renders `cells` row-major into a fixed `cols × rows` grid of `tile`-sized cells (no scrolling).
    private func fixedGrid(_ cells: [FringeCell], cols: Int, rows: Int, tile: CGFloat, scale: Double) -> some View {
        VStack(spacing: Self.boardSpacing) {
            ForEach(0 ..< rows, id: \.self) { r in
                HStack(spacing: Self.boardSpacing) {
                    ForEach(0 ..< cols, id: \.self) { c in
                        let idx = r * cols + c
                        cellView(idx < cells.count ? cells[idx] : nil, tile: tile, scale: scale)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cellView(_ cell: FringeCell?, tile: CGFloat, scale: Double) -> some View {
        Group {
            switch cell {
            case .word(let word):
                wordTile(word, scale: scale)
            case .blank:
                BlankTileView()
            case .folder(let name, let icon, let color):
                FolderTileView(title: name, icon: icon, color: color, scale: scale,
                               style: store.settings.tileStyle) {
                    open(folder: name)
                }
            case .favorites:
                FolderTileView(title: "Favorites", icon: "⭐️", color: Self.favoritesColor,
                               scale: scale, style: store.settings.tileStyle) {
                    open(folder: Self.favoritesCategoryToken)
                }
            case .back:
                backTile(scale: scale)
            case nil:
                Color.clear
            }
        }
        .frame(width: tile, height: tile)
    }

    /// A "Home" tile (board button) that returns to the home page. Lives as the first cell of a folder
    /// page so back-navigation always works (board tiles reliably receive taps).
    private func backTile(scale: Double) -> some View {
        let clamped = min(max(scale, 0.7), 1.8)
        return Button {
            open(folder: nil)
        } label: {
            VStack(spacing: 6 * clamped) {
                Image(systemName: "house.fill")
                    .font(.system(size: 36 * clamped, weight: .bold))
                    .foregroundStyle(.white)
                Text("Home")
                    .font(.system(size: 17 * clamped, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(8 * clamped)
            .background(
                LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.82)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8 * clamped, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(PressableTileStyle())
        .accessibilityLabel("Home")
    }

    @ViewBuilder
    private func wordTile(_ word: AACWord, scale: Double? = nil) -> some View {
        WordTileView(word: word, action: {
            addWord(word)
        }, scale: scale ?? store.settings.tileScale,
           backgroundColor: store.tileColor(for: word),
           style: store.settings.tileStyle)
        .contextMenu {
            Button {
                speech.speak(word.phrase, settings: store.settings)
            } label: {
                Label("Speak", systemImage: "speaker.wave.2")
            }
            Button {
                store.toggleFavorite(for: word)
                Haptics.success()
            } label: {
                Label(word.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                      systemImage: word.isFavorite ? "star.slash" : "star")
            }
            Button {
                store.addQuickPhrase(word.phrase)
                Haptics.success()
            } label: {
                Label("Add to Quick Phrases", systemImage: "quote.bubble")
            }
        }
    }

    private func addWord(_ word: AACWord) {
        composer.append(word)
        speech.speak(word.phrase, settings: store.settings)
        history.record(wordId: word.id, label: word.label, enabled: store.settings.trackUsageHistory)
    }

    private func handleQuickPhrase(_ phrase: QuickPhrase) {
        Haptics.actionTap()
        switch phrase.mode {
        case .speak, .regulation:
            speech.speak(phrase.text, settings: store.settings)
            history.recordSentence(phrase.text, enabled: store.settings.trackUsageHistory)
        case .startSentence:
            let starterWord = AACWord(
                label: phrase.text,
                phrase: phrase.text,
                symbol: "💬",
                category: "Phrase",
                colorName: .purple,
                position: 0
            )
            composer.append(starterWord)
        }
    }

    private func speakMessage() {
        guard let polished = composer.polishedSentence else { return }
        Haptics.actionTap()
        speech.speak(polished, settings: store.settings)
        history.recordSentence(polished, enabled: store.settings.trackUsageHistory)
    }

    private func removeLastWord() {
        composer.removeLast()
    }

    private func clearMessage() {
        composer.clear()
    }
}
