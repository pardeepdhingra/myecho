import SwiftUI
import UIKit

struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}

/// Sheet for customizing a single category's color + icon. Categories are derived from words, so this
/// edits the style only; an unset category falls back to `CategoryDefaults`.
private struct CategoryStyleEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AACStore

    let categoryName: String

    @State private var colorName: TileColorName = .blue
    @State private var icon: String = "🗂️"
    @State private var showingEmojiPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(colorName.color)
                                Text(icon)
                                    .font(.system(size: 48))
                            }
                            .frame(width: 96, height: 96)
                            Text(categoryName)
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                Section("Icon") {
                    Button {
                        showingEmojiPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Text(icon)
                                .font(.system(size: 32))
                                .frame(width: 52, height: 52)
                                .background(Color.gray.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            Text("Choose an icon")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Section("Color") {
                    Picker("Color", selection: $colorName) {
                        ForEach(TileColorName.allCases) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 16, height: 16)
                                Text(color.label)
                            }
                            .tag(color)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                if store.explicitCategoryStyle(for: categoryName) != nil {
                    Section {
                        Button("Reset to default", role: .destructive) {
                            store.clearCategoryStyle(name: categoryName)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        store.setCategoryStyle(name: categoryName, colorName: colorName, icon: icon)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView { emoji in
                    icon = emoji
                }
            }
            .onAppear {
                let resolved = store.resolvedCategoryStyle(for: categoryName)
                colorName = resolved.colorName
                icon = resolved.icon
            }
        }
    }
}

private struct PhraseEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var phrase: QuickPhrase
    let onSave: (QuickPhrase) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Phrase") {
                    TextField("Text", text: $phrase.text, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Picker("When tapped", selection: $phrase.mode) {
                        ForEach(QuickPhraseMode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }

                    if phrase.mode == .regulation {
                        Picker("Style", selection: Binding(
                            get: { phrase.regulationKind ?? .help },
                            set: { phrase.regulationKind = $0 }
                        )) {
                            Label("Calm (teal)", systemImage: "leaf.fill").tag(RegulationKind.calm)
                            Label("Help (yellow)", systemImage: "questionmark.bubble.fill").tag(RegulationKind.help)
                            Label("Stop (red)", systemImage: "hand.raised.fill").tag(RegulationKind.stop)
                        }
                    }
                } footer: {
                    Text("• Speak immediately — says the phrase out loud.\n• Add to message bar — sentence starter the child extends before tapping Speak.\n• Pinned regulation button — appears at the very top of the kid screen as a colored emergency button (Break / Help / Stop style).")
                }
            }
            .navigationTitle("Edit Phrase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if phrase.mode == .regulation, phrase.regulationKind == nil {
                            phrase.regulationKind = .help
                        }
                        onSave(phrase)
                        dismiss()
                    }
                    .disabled(phrase.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct ParentModeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AACStore
    @EnvironmentObject private var speech: SpeechService
    @EnvironmentObject private var history: UsageHistory

    @State private var editedWord: AACWord?
    @State private var editedPhrase: QuickPhrase?
    @State private var editedCategory: IdentifiableString?
    @State private var newPhraseText: String = ""
    @State private var showingResetAlert = false
    @State private var starterMergeMessage: String?
    @State private var wordSearch: String = ""
    @State private var visibilityFilter: VisibilityFilter = .all
    @State private var showingBulkSign = false

    private enum VisibilityFilter: String, CaseIterable {
        case all, visible, hidden
        var label: String {
            switch self {
            case .all: "All"
            case .visible: "Visible"
            case .hidden: "Hidden"
            }
        }
    }
    @State private var exportURL: IdentifiableURL?
    @State private var showingImporter = false
    @State private var importAlert: ImportAlert?

    private struct ImportAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    var body: some View {
        NavigationStack {
            TabView {
                boardSettings
                    .tabItem {
                        Label("Board", systemImage: "square.grid.3x3")
                    }

                wordList
                    .tabItem {
                        Label("Words", systemImage: "text.badge.plus")
                    }

                phraseList
                    .tabItem {
                        Label("Phrases", systemImage: "quote.bubble")
                    }

                statsView
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar")
                    }

                voiceSettings
                    .tabItem {
                        Label("Voice", systemImage: "speaker.wave.2")
                    }

                AccountView()
                    .tabItem {
                        Label("Account", systemImage: "icloud")
                    }
            }
            .navigationTitle("Parent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editedWord = store.addBlankWord()
                    } label: {
                        Label("Add word", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editedWord) { word in
                EditWordView(word: word)
                    .environmentObject(store)
                    .environmentObject(speech)
            }
            .alert("Reset starter board?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetStarterBoard()
                }
            } message: {
                Text("This replaces your custom words and voice settings with the starter board.")
            }
            .alert("Starter vocabulary", isPresented: Binding(
                get: { starterMergeMessage != nil },
                set: { if !$0 { starterMergeMessage = nil } }
            )) {
                Button("OK", role: .cancel) { starterMergeMessage = nil }
            } message: {
                Text(starterMergeMessage ?? "")
            }
        }
    }

    /// Swatch + label for each word type, shown when "By word type" coloring is active.
    private var wordTypeLegend: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(PartOfSpeech.allCases) { pos in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(pos.defaultColor.color)
                        .frame(width: 26, height: 20)
                        .overlay {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(.black.opacity(0.12), lineWidth: 1)
                        }
                    Text(pos.label)
                        .font(.callout)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var boardSettings: some View {
        Form {
            Section {
                if store.settings.boardMode == .folders {
                    Picker("Grid size", selection: $store.settings.gridPreset) {
                        ForEach(GridPreset.allCases) { preset in
                            Text(preset.label).tag(preset)
                        }
                    }
                    if store.settings.gridPreset == .custom {
                        Stepper(value: $store.settings.gridColumns, in: AACSettings.minGridColumns...AACSettings.maxGridColumns) {
                            HStack { Text("Columns"); Spacer()
                                Text("\(store.settings.gridColumns)").font(.body.monospacedDigit()).foregroundStyle(.secondary) }
                        }
                        Stepper(value: $store.settings.gridRows, in: 3...12) {
                            HStack { Text("Rows"); Spacer()
                                Text("\(store.settings.gridRows)").font(.body.monospacedDigit()).foregroundStyle(.secondary) }
                        }
                    }
                    Stepper(value: $store.settings.coreColumns, in: 0...AACSettings.maxCoreColumns) {
                        HStack { Text("Core columns (fixed buttons)"); Spacer()
                            Text("\(store.settings.coreColumns)").font(.body.monospacedDigit()).foregroundStyle(.secondary) }
                    }
                } else {
                    Stepper(value: gridColumnsBinding, in: AACSettings.minGridColumns...AACSettings.maxGridColumns) {
                        HStack {
                            Text("Columns")
                            Spacer()
                            Text("\(clampedGridColumns) × \(clampedGridColumns)")
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Toggle("Show categories on kid screen", isOn: $store.settings.showCategoryFilter)
                }

                Toggle("Show quick phrases", isOn: $store.settings.showQuickPhrases)
                Toggle("Show symbols in message bar", isOn: $store.settings.showSymbolsInMessageBar)
                Toggle("Show regulation bar (Break / Help / Stop)", isOn: $store.settings.showRegulationBar)
                Toggle("Word suggestions", isOn: $store.settings.showWordSuggestions)
                Toggle("Keyboard page (type to speak)", isOn: $store.settings.showKeyboardPage)
                Toggle("Switch scanning", isOn: $store.settings.scanningEnabled)
                if store.settings.scanningEnabled {
                    Stepper(
                        value: $store.settings.scanIntervalSeconds,
                        in: 0.5...10.0, step: 0.5
                    ) {
                        Text("Scan speed: \(store.settings.scanIntervalSeconds, specifier: "%.1f")s")
                    }
                }
            } header: {
                Text("Grid")
            } footer: {
                if store.settings.boardMode == .folders {
                    Text("Motor Plan sizes fill the screen with no scrolling (extra words page sideways). \"Core columns\" reserve the left side for the always-visible core words.")
                } else {
                    Text("Up to \(AACSettings.maxGridColumns) columns on this device — iPad in landscape fits the most. Larger grids show more words at once; smaller grids make each tile bigger.")
                }
            }

            Section {
                Picker("Board layout", selection: $store.settings.boardMode) {
                    ForEach(BoardMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                Picker("Tile style", selection: $store.settings.tileStyle) {
                    ForEach(TileStyle.allCases) { s in
                        Text(s.label).tag(s)
                    }
                }
                if store.settings.boardMode == .folders {
                    NavigationLink {
                        folderOrderView
                    } label: {
                        HStack {
                            Label("Folders — reorder, hide/show", systemImage: "folder")
                            Spacer()
                            Text("\(allFolderNames.count)")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
                if store.settings.boardMode == .classic {
                    Toggle("Freeze button positions", isOn: $store.settings.freezeButtonPositions)
                }
            } header: {
                Text("Layout")
            } footer: {
                if store.settings.boardMode == .folders {
                    Text("Folders (Motor Plan) gives every word one fixed location: the home page shows core words plus a folder for each category. Tapping a folder opens its words in a fixed grid that never rearranges — easier to learn by muscle memory.")
                } else {
                    Text("Classic shows a scrolling grid with a category filter. \"Freeze button positions\" keeps each button in the same spot when you filter by a category; empty spaces appear where words from other categories would be.")
                }
            }

            Section {
                Picker("Color tiles", selection: $store.settings.colorMode) {
                    ForEach(ColorMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                if store.settings.colorMode == .byWordType {
                    wordTypeLegend
                }
                NavigationLink {
                    categoryStyleList
                } label: {
                    HStack {
                        Label("Categories", systemImage: "square.grid.2x2")
                        Spacer()
                        Text("\(store.categories.count)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Colors")
            } footer: {
                switch store.settings.colorMode {
                case .byCategory:
                    Text("Every card in a category shares that category's color. Each category has its own color and icon to help kids recognize it.")
                case .perWord:
                    Text("Each tile uses its own color, which you set in Edit Word.")
                case .byWordType:
                    Text("Tiles are colored by word type (the Fitzgerald Key used in many AAC systems), so nouns, verbs, describing words, and so on are each a consistent color. Set a word's type in Edit Word.")
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Tile size")
                        Spacer()
                        Text(tileScaleLabel)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $store.settings.tileScale, in: 0.7...1.8, step: 0.05) {
                        Text("Tile size")
                    } minimumValueLabel: {
                        Image(systemName: "textformat.size.smaller")
                    } maximumValueLabel: {
                        Image(systemName: "textformat.size.larger")
                    }
                }

                HStack {
                    Button("Small") { store.settings.tileScale = 0.8 }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Button("Medium") { store.settings.tileScale = 1.0 }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Button("Large") { store.settings.tileScale = 1.3 }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Button("XL") { store.settings.tileScale = 1.6 }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            } header: {
                Text("Tile size")
            } footer: {
                Text("Scales the whole tile — text, emoji, photo, and padding — together. Try a smaller grid (3 or 4 columns) with larger tiles for younger or motor-skill-developing kids.")
            }

            Section {
                Button {
                    let result = store.mergeStarterVocabulary()
                    starterMergeMessage = result.wordsAdded == 0
                        ? "Your board already has all the starter words."
                        : "Added \(result.wordsAdded) word\(result.wordsAdded == 1 ? "" : "s") (skipped \(result.wordsSkipped) you already have)."
                } label: {
                    Label("Add starter vocabulary", systemImage: "text.book.closed")
                }
                NavigationLink {
                    routinePacksView
                } label: {
                    Label("Add routine pack", systemImage: "square.stack.3d.up")
                }
                NavigationLink {
                    favoritesOrderView
                } label: {
                    HStack {
                        Label("Order favorites", systemImage: "star")
                        Spacer()
                        Text("\(store.favoritesOrdered.count)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("Add the full set of built-in words (organized into folders, color-coded by word type) without changing words you already have. Or add curated routine packs, or drag-reorder the ★ Favorites words.")
            }

            Section("Learning") {
                Text("Keep familiar words in the same position. Hide words while learning, then reveal more without rearranging the board.")
                    .foregroundStyle(.secondary)
            }

            Section {
                NavigationLink {
                    BoardSetsView()
                        .environmentObject(store)
                } label: {
                    Label("Board sets", systemImage: "square.stack.3d.up")
                }
            } header: {
                Text("Board sets")
            } footer: {
                Text("Save the board as named sets — Home, School, Therapy — and switch between them.")
            }

            Section {
                Button {
                    if let url = BoardBackup.exportToTempFile(store: store) {
                        exportURL = IdentifiableURL(url: url)
                    }
                } label: {
                    Label("Export board", systemImage: "square.and.arrow.up")
                }

                Button {
                    showingImporter = true
                } label: {
                    Label("Import board", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("Backup")
            } footer: {
                Text("Export a single .vaniboard file with every word, phrase, setting, and photo. Save it to Files, email it, or AirDrop it — then import on another device.")
            }

            Section {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About Vani", systemImage: "info.circle")
                }
            }

            Section {
                Button("Reset starter board", role: .destructive) {
                    showingResetAlert = true
                }
            }
        }
        .sheet(item: $exportURL) { wrapper in
            ShareSheet(items: [wrapper.url])
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                if BoardBackup.importFromFile(url, into: store) {
                    Haptics.success()
                    importAlert = ImportAlert(title: "Imported", message: "Your board has been replaced from the file.")
                } else {
                    importAlert = ImportAlert(title: "Import failed", message: "Could not read that file as a Vani backup.")
                }
            case .failure(let error):
                importAlert = ImportAlert(title: "Import failed", message: error.localizedDescription)
            }
        }
        .alert(item: $importAlert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
        .sheet(item: $editedCategory) { wrapper in
            CategoryStyleEditor(categoryName: wrapper.value)
                .environmentObject(store)
        }
    }

    private var clampedGridColumns: Int {
        min(max(store.settings.gridColumns, AACSettings.minGridColumns), AACSettings.maxGridColumns)
    }

    /// Stepper binding that keeps the stored column count within this device's allowed range (a board
    /// synced from an iPad could carry 12 columns into an iPhone, where the max is lower).
    private var gridColumnsBinding: Binding<Int> {
        Binding(
            get: { clampedGridColumns },
            set: { store.settings.gridColumns = $0 }
        )
    }

    private var categoryStyleList: some View {
        List {
            Section {
                ForEach(store.categories, id: \.self) { category in
                    let style = store.resolvedCategoryStyle(for: category)
                    let count = store.words.filter { $0.category == category }.count
                    Button {
                        editedCategory = IdentifiableString(value: category)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(style.color)
                                Text(style.icon)
                                    .font(.system(size: 24))
                            }
                            .frame(width: 46, height: 46)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(category)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(count) word\(count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if store.explicitCategoryStyle(for: category) != nil {
                                Text("Custom")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                Text("Tap a category to change its color and icon. Categories are created when you assign words to them in Edit Word.")
            }
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func wordRowThumbnail(for word: AACWord) -> some View {
        if let filename = word.imagePath, let image = ImageStore.load(filename) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let signFilename = word.signVideoPath, SignVideoStore.exists(signFilename) {
            SignVideoView(url: SignVideoStore.fileURL(for: signFilename), videoGravity: .resizeAspectFill)
                .allowsHitTesting(false)
        } else {
            Text(word.symbol)
                .font(.largeTitle)
        }
    }

    private var tileScaleLabel: String {
        let s = store.settings.tileScale
        if s < 0.9 { return "Small" }
        if s < 1.15 { return "Medium" }
        if s < 1.45 { return "Large" }
        return "Extra Large"
    }

    private var filteredWords: [AACWord] {
        let term = wordSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return store.words
            .sorted { $0.position < $1.position }
            .filter { word in
                switch visibilityFilter {
                case .all: true
                case .visible: word.isVisible
                case .hidden: !word.isVisible
                }
            }
            .filter { word in
                guard !term.isEmpty else { return true }
                return word.label.lowercased().contains(term)
                    || word.category.lowercased().contains(term)
                    || word.phrase.lowercased().contains(term)
            }
    }

    private var wordList: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search words", text: $wordSearch)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !wordSearch.isEmpty {
                        Button {
                            wordSearch = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                Picker("Show", selection: $visibilityFilter) {
                    ForEach(VisibilityFilter.allCases, id: \.self) { filter in
                        Text(filter.label).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            ForEach(filteredWords) { word in
                HStack(spacing: 12) {
                    wordRowThumbnail(for: word)
                        .frame(width: 46, height: 46)
                        .background(store.tileColor(for: word))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Text(word.label)
                                .font(.headline)
                            if word.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.yellow)
                            }
                        }
                        Text(word.category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        store.toggleVisibility(for: word)
                    } label: {
                        Image(systemName: word.isVisible ? "eye" : "eye.slash")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(word.isVisible ? "Hide word" : "Show word")
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    editedWord = word
                }
            }
            .onMove { offsets, destination in
                let visibleIds = filteredWords.map(\.id)
                if visibleIds.count == store.words.count {
                    store.moveWords(ids: visibleIds, from: offsets, to: destination)
                }
            }
            .onDelete { offsets in
                offsets.map { filteredWords[$0] }.forEach(store.delete)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingBulkSign = true
                } label: {
                    Label("Add Signs", systemImage: "hand.raised")
                }
            }
        }
        .sheet(isPresented: $showingBulkSign) {
            BulkSignView()
                .environmentObject(store)
        }
    }

    private var phraseList: some View {
        List {
            Section {
                HStack {
                    TextField("Add a quick phrase", text: $newPhraseText)
                        .submitLabel(.done)
                        .onSubmit { addPhrase() }
                    Button {
                        addPhrase()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(newPhraseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } footer: {
                Text("Phrases appear as one-tap chips above the message bar on the kid screen.")
            }

            Section("Phrases") {
                ForEach(store.quickPhrases.sorted { $0.position < $1.position }) { phrase in
                    HStack {
                        Text(phrase.text)
                        Spacer()
                        Button {
                            speech.speak(phrase.text, settings: store.settings)
                        } label: {
                            Image(systemName: "play.circle")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Preview phrase")
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editedPhrase = phrase
                    }
                }
                .onMove { offsets, destination in
                    store.moveQuickPhrase(from: offsets, to: destination)
                }
                .onDelete { offsets in
                    let sorted = store.quickPhrases.sorted { $0.position < $1.position }
                    offsets.map { sorted[$0] }.forEach(store.deleteQuickPhrase)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $editedPhrase) { phrase in
            PhraseEditSheet(phrase: phrase) { updated in
                store.updateQuickPhrase(updated)
            }
        }
    }

    private func addPhrase() {
        store.addQuickPhrase(newPhraseText)
        newPhraseText = ""
    }

    /// Non-core categories (folders) with ≥1 visible word, in the same order the kid board uses.
    private var folderCategoryNames: [String] {
        let visible = store.words
            .filter { $0.isVisible && $0.category != AACWord.coreCategory }
            .sorted { $0.position < $1.position }
            .map(\.category)
        let distinct = (Array(NSOrderedSet(array: visible)) as? [String]) ?? []
        let order = store.settings.categoryOrder
        guard !order.isEmpty else { return distinct }
        let ordered = order.filter { distinct.contains($0) }
        let rest = distinct.filter { !ordered.contains($0) }
        return ordered + rest
    }

    /// Every folder (non-core category), including hidden ones, in board order — so the manager can
    /// re-show a hidden folder.
    private var allFolderNames: [String] {
        let distinct = store.categories.filter { $0 != AACWord.coreCategory }
        let order = store.settings.categoryOrder
        guard !order.isEmpty else { return distinct }
        let ordered = order.filter { distinct.contains($0) }
        let rest = distinct.filter { !ordered.contains($0) }
        return ordered + rest
    }

    private var folderOrderView: some View {
        List {
            Section {
                if allFolderNames.isEmpty {
                    Text("No folders yet. Folders are the categories your words belong to (set a word's category in Edit Word).")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(allFolderNames, id: \.self) { name in
                        folderManagerRow(name)
                    }
                    .onMove { offsets, destination in
                        var arr = allFolderNames
                        arr.move(fromOffsets: offsets, toOffset: destination)
                        store.settings.categoryOrder = arr
                    }
                }
            } footer: {
                Text("Drag to reorder. Tap the eye to hide or show a whole folder on the kid screen — its words are kept, just hidden.")
            }
        }
        .navigationTitle("Folders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
        }
    }

    @ViewBuilder
    private func folderManagerRow(_ name: String) -> some View {
        let style = store.resolvedCategoryStyle(for: name)
        let hidden = store.isFolderHidden(name)
        HStack(spacing: 12) {
            Text(style.icon).font(.title3)
                .frame(width: 38, height: 38)
                .background(style.color.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.headline)
                if hidden {
                    Text("Hidden").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                store.setFolder(name, hidden: !hidden)
            } label: {
                Image(systemName: hidden ? "eye.slash" : "eye")
                    .font(.title3)
                    .foregroundStyle(hidden ? Color.secondary : Color.accentColor)
            }
            .buttonStyle(.plain)
        }
        .opacity(hidden ? 0.55 : 1)
    }

    private var favoritesOrderView: some View {
        List {
            if store.favoritesOrdered.isEmpty {
                Text("No favorites yet. Long-press a tile on the kid screen → Add to Favorites, or toggle Favorite in Edit Word.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.favoritesOrdered) { word in
                    HStack(spacing: 12) {
                        wordRowThumbnail(for: word)
                            .frame(width: 38, height: 38)
                            .background(store.tileColor(for: word))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text(word.label)
                            .font(.headline)
                        Spacer()
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                }
                .onMove { offsets, destination in
                    store.moveFavorites(from: offsets, to: destination)
                }
            }
        }
        .navigationTitle("Order favorites")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
    }

    private var routinePacksView: some View {
        List(RoutinePacks.all) { pack in
            packRow(for: pack)
        }
        .navigationTitle("Routine packs")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func packRow(for pack: RoutinePack) -> some View {
        let status = store.packStatus(pack)
        let isAdded = status.addedWords > 0 || status.addedPhrases > 0
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(pack.symbol)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(pack.title)
                        .font(.headline)
                    Text(pack.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isAdded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            if isAdded {
                Text("Currently in your board from this pack: \(status.addedWords) words, \(status.addedPhrases) phrases.")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Text("Adds \(pack.words.count) words and \(pack.phrases.count) phrases. Duplicates (already in your board) are skipped.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if isAdded {
                Button(role: .destructive) {
                    store.removePack(pack)
                    Haptics.actionTap()
                } label: {
                    Label("Remove pack", systemImage: "minus.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Button {
                    store.mergePack(pack)
                    Haptics.success()
                } label: {
                    Label("Add to board", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    private var statsView: some View {
        Form {
            Section {
                Toggle("Track tile taps on this device", isOn: $store.settings.trackUsageHistory)
                Text("All data stays on this iPhone. Nothing is uploaded.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Today") {
                let today = history.countsInLast(hours: 24)
                if today.isEmpty {
                    Text("No taps tracked today.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(today.prefix(10), id: \.label) { row in
                        HStack {
                            Text(row.label)
                            Spacer()
                            Text("\(row.count)")
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("This week") {
                let week = history.countsInLast(hours: 24 * 7)
                if week.isEmpty {
                    Text("No taps tracked this week.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(week.prefix(10), id: \.label) { row in
                        HStack {
                            Text(row.label)
                            Spacer()
                            Text("\(row.count)")
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Recent sentences") {
                if history.spokenSentences.isEmpty {
                    Text("No sentences spoken yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(history.spokenSentences.prefix(10), id: \.self) { sentence in
                        Text(sentence)
                            .font(.body)
                    }
                }
            }

            Section {
                Button("Clear tap history", role: .destructive) {
                    history.clear()
                }
                Button("Clear sentence history", role: .destructive) {
                    history.clearSentences()
                }
            }
        }
    }

    private var voiceSettings: some View {
        Form {
            Section {
                let filteredVoices = speech.voiceOptions(includeCompact: store.settings.showAllVoiceQualities)

                Picker("Voice", selection: $store.settings.voiceIdentifier) {
                    Text("Best available").tag(String?.none)
                    ForEach(filteredVoices) { voice in
                        Text(voice.displayName).tag(Optional(voice.id))
                    }
                }

                if !speech.hasAnyEnhancedOrPremiumVoice {
                    Text("No Premium or Enhanced voices are downloaded on this iPhone yet. The default voice will sound robotic until you download one. See instructions below.")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }

                Toggle("Show robotic (compact) voices too", isOn: $store.settings.showAllVoiceQualities)
                    .font(.footnote)

                Button {
                    speech.previewVoice(settings: store.settings)
                } label: {
                    Label("Preview voice", systemImage: "play.circle")
                }

                Button {
                    if let url = URL(string: "App-prefs:ACCESSIBILITY&path=SPEECH/Voices") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Download Premium voices", systemImage: "arrow.down.circle")
                }
            } header: {
                Text("System voice")
            } footer: {
                Text("By default this picker only shows voices marked Premium or Enhanced — the natural-sounding ones. The rest of iOS's voices are \"Compact\" — small files that sound robotic.\n\nTo unlock more natural voices:\n1. iPhone Settings → Accessibility → Spoken Content → Voices → English\n2. Pick a voice (e.g. Ava, Evan, Karen, Joelle, Daniel, Serena)\n3. Tap the cloud icon next to Premium (~100 MB) or Enhanced (~50 MB)\n4. Come back here — the new voice will appear in the picker.\n\nFor true human-sounding speech on iPhone, Premium beats Enhanced beats Compact.")
            }

            Section("Sound") {
                VStack(alignment: .leading) {
                    Text("Speed")
                    Slider(value: $store.settings.speechRate, in: 0.32...0.58)
                }

                VStack(alignment: .leading) {
                    Text("Pitch")
                    Slider(value: $store.settings.pitchMultiplier, in: 0.85...1.25)
                }
            }
        }
    }
}
