import PhotosUI
import SwiftUI
import UIKit

struct EditWordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AACStore
    @EnvironmentObject private var speech: SpeechService

    @State private var draft: AACWord
    @State private var originalImagePath: String?
    @State private var originalSignVideoPath: String?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingEmojiPicker = false
    @State private var showingSymbolPicker = false
    @State private var showingSignPicker = false
    @State private var showingSignThumbnailPicker = false
    @State private var showCustomSymbol = false
    @State private var isAddingNewCategory = false
    @State private var newCategoryText: String = ""
    @State private var newFormText: String = ""
    /// Remembers the folder to return a word to when it's un-pinned from the home core band.
    @State private var lastFolder: String
    @State private var phraseFollowsLabel: Bool

    init(word: AACWord) {
        _draft = State(initialValue: word)
        _originalImagePath = State(initialValue: word.imagePath)
        _originalSignVideoPath = State(initialValue: word.signVideoPath)
        let labelMatchesPhrase = word.label
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .caseInsensitiveCompare(word.phrase.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
        _phraseFollowsLabel = State(initialValue: labelMatchesPhrase)
        _lastFolder = State(initialValue: word.category == AACWord.coreCategory ? "" : word.category)
    }

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    private var previewTileColor: Color {
        store.tileColor(for: draft)
    }

    private var pronunciationSuggestion: String? {
        guard let suggestion = PronunciationService.suggestion(for: draft.label) else { return nil }
        let current = draft.phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        return suggestion.caseInsensitiveCompare(current) == .orderedSame ? nil : suggestion
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Word") {
                    TextField("Label", text: $draft.label)
                    TextField("Spoken phrase", text: $draft.phrase)
                    pronunciationRow
                    symbolRow
                    pictureSymbolRow
                    if showCustomSymbol {
                        TextField("Custom symbol", text: $draft.symbol)
                    }
                    pinToHomeRow
                    if draft.category != AACWord.coreCategory {
                        categoryRow
                    }
                }

                photoSection

                signSection

                wordFormsSection

                Section {
                    Picker("Word type", selection: $draft.partOfSpeech) {
                        Text("None").tag(PartOfSpeech?.none)
                        ForEach(PartOfSpeech.allCases) { pos in
                            HStack {
                                Circle()
                                    .fill(pos.defaultColor.color)
                                    .frame(width: 16, height: 16)
                                Text(pos.label)
                            }
                            .tag(PartOfSpeech?.some(pos))
                        }
                    }

                    Picker("Button color", selection: $draft.colorOverride) {
                        Text("Match folder color").tag(TileColorName?.none)
                        ForEach(TileColorName.allCases) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 16, height: 16)
                                Text(color.label)
                            }
                            .tag(TileColorName?.some(color))
                        }
                    }

                    Toggle("Visible on kid screen", isOn: $draft.isVisible)
                    Toggle("Favorite (shows in ★ Favorites)", isOn: $draft.isFavorite)
                } header: {
                    Text("Board")
                } footer: {
                    if draft.colorOverride == nil {
                        Text("By default this button uses its folder's color (“\(draft.category)”). Pick a specific color above to make just this one button different.")
                    } else {
                        Text("This button uses a custom color. Choose “Match folder color” to follow the “\(draft.category)” folder again.")
                    }
                }

                Section("Preview") {
                    WordTileView(word: draft, action: {}, scale: store.settings.tileScale,
                                 backgroundColor: previewTileColor, style: store.settings.tileStyle)
                        .frame(maxWidth: 220)
                        .disabled(true)
                }
            }
            .navigationTitle("Edit Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        cancel()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(draft.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: photoPickerItem) { _, newItem in
                guard let newItem else { return }
                Task { await loadPhotoPickerItem(newItem) }
            }
            .onChange(of: draft.label) { _, newValue in
                if phraseFollowsLabel {
                    draft.phrase = PronunciationService.bestSpokenPhrase(for: newValue)
                }
            }
            .onChange(of: draft.phrase) { _, newValue in
                let trimmedLabel = draft.label.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedPhrase = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedPhrase.caseInsensitiveCompare(trimmedLabel) != .orderedSame {
                    phraseFollowsLabel = false
                } else if trimmedPhrase == trimmedLabel {
                    phraseFollowsLabel = true
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker { image in
                    handlePicked(image: image)
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView { emoji in
                    draft.symbol = emoji
                    draft.symbolName = nil   // choosing an emoji clears the picture symbol
                }
            }
            .sheet(isPresented: $showingSymbolPicker) {
                SymbolPickerView(
                    onSelect: { name in
                        draft.symbolName = name
                    },
                    onSelectImage: { path in
                        // Image already saved to ImageStore by the picker; clear symbolName so photo takes priority.
                        let previousDuringEdit = draft.imagePath
                        draft.imagePath = path
                        draft.symbolName = nil
                        if let previousDuringEdit, previousDuringEdit != originalImagePath {
                            ImageStore.delete(previousDuringEdit)
                        }
                    }
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingSignPicker) {
                SignPickerView(initialWord: draft.label) { selection in
                    handlePickedSign(selection)
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingSignThumbnailPicker) {
                if let videoPath = draft.signVideoPath {
                    SignThumbnailPickerView(
                        videoPath: videoPath,
                        currentThumbnailPath: draft.signThumbnailPath
                    ) { newPath in
                        draft.signThumbnailPath = newPath
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var pronunciationRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Pronunciation")
                        .font(.subheadline.weight(.semibold))
                    Text("Hear how this word will sound.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    let spoken = draft.phrase.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !spoken.isEmpty else { return }
                    speech.speak(spoken, settings: store.settings)
                } label: {
                    Label("Hear", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.bordered)
                .disabled(draft.phrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Hear how this word will sound")
            }

            if let suggestion = pronunciationSuggestion {
                Divider()
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Suggested pronunciation")
                            .font(.subheadline.weight(.semibold))
                        Text(suggestion)
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        speech.speak(suggestion, settings: store.settings)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Preview suggested pronunciation")
                }

                Button {
                    draft.phrase = suggestion
                    phraseFollowsLabel = false
                    Haptics.success()
                } label: {
                    Label("Use suggestion", systemImage: "text.bubble")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 4)
    }

    private var existingCategories: [String] {
        let all = Set(store.words.map(\.category)).filter { !$0.isEmpty }
        return all.sorted()
    }

    @ViewBuilder
    private var pinToHomeRow: some View {
        Toggle(isOn: Binding(
            get: { draft.category == AACWord.coreCategory },
            set: { pin in
                if pin {
                    if draft.category != AACWord.coreCategory { lastFolder = draft.category }
                    draft.category = AACWord.coreCategory
                } else {
                    let fallback = store.categories.first { $0 != AACWord.coreCategory } ?? "More"
                    draft.category = lastFolder.isEmpty ? fallback : lastFolder
                }
            }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pin to home (fixed button)")
                Text("Keeps this button in the fixed area on the home page. Turn off to put it inside a folder instead.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var categoryRow: some View {
        if isAddingNewCategory {
            HStack {
                TextField("New category", text: $newCategoryText)
                    .autocorrectionDisabled()
                Button("Done") {
                    let trimmed = newCategoryText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        draft.category = trimmed
                    }
                    isAddingNewCategory = false
                    newCategoryText = ""
                }
                .disabled(newCategoryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } else {
            Picker("Category", selection: Binding(
                get: { draft.category },
                set: { newValue in
                    if newValue == "__new__" {
                        newCategoryText = ""
                        isAddingNewCategory = true
                    } else {
                        draft.category = newValue
                    }
                }
            )) {
                ForEach(existingCategories, id: \.self) { category in
                    Text(category).tag(category)
                }
                if !existingCategories.contains(draft.category) && !draft.category.isEmpty {
                    Text(draft.category).tag(draft.category)
                }
                Divider()
                Text("+ New category…").tag("__new__")
            }
        }
    }

    @ViewBuilder
    private var symbolRow: some View {
        HStack {
            Button {
                showingEmojiPicker = true
            } label: {
                HStack(spacing: 12) {
                    Text(draft.symbol.isEmpty ? "💬" : draft.symbol)
                        .font(.system(size: 36))
                        .frame(width: 52, height: 52)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Symbol")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Text("Tap to choose an emoji")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }

        Toggle("Use a custom symbol instead", isOn: $showCustomSymbol)
            .font(.footnote)
    }

    @ViewBuilder
    private var pictureSymbolRow: some View {
        Button {
            showingSymbolPicker = true
        } label: {
            HStack(spacing: 12) {
                Group {
                    if let s = draft.symbolName, SymbolLibrary.exists(s) {
                        Image(s).resizable().scaledToFit().padding(4)
                    } else {
                        Image(systemName: "photo.artframe").foregroundStyle(.secondary)
                    }
                }
                .frame(width: 52, height: 52)
                .background(Color.gray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Picture symbol")
                        .font(.subheadline).foregroundStyle(.primary)
                    Text(draft.symbolName == nil ? "Tap to choose an AAC symbol" : "Symbol set — tap to change")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var wordFormsSection: some View {
        Section {
            ForEach(draft.wordForms, id: \.self) { form in
                HStack {
                    Text(form)
                        .font(.system(.body, design: .rounded))
                    Spacer()
                    Button {
                        draft.wordForms.removeAll { $0 == form }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(form)")
                }
            }

            HStack {
                TextField("Add a form (e.g. eating)", text: $newFormText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .onSubmit { addForm() }
                Button(action: addForm) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                .disabled(newFormText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Add form")
            }
        } header: {
            Text("Word forms")
        } footer: {
            Text("Alternative forms (e.g. eating, ate, eats) that the child can pick with a long press in kid mode.")
        }
    }

    private func addForm() {
        let trimmed = newFormText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !draft.wordForms.contains(trimmed) else { return }
        draft.wordForms.append(trimmed)
        newFormText = ""
    }

    @ViewBuilder
    private var photoSection: some View {
        Section("Photo") {
            HStack(spacing: 14) {
                photoThumbnail
                VStack(alignment: .leading, spacing: 4) {
                    Text(draft.imagePath == nil ? "No photo" : "Photo attached")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Photos appear on the tile instead of the emoji.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            PhotosPicker(
                selection: $photoPickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("Choose from library", systemImage: "photo.on.rectangle")
            }

            if cameraAvailable {
                Button {
                    showingCamera = true
                } label: {
                    Label("Take photo", systemImage: "camera")
                }
            }

            if draft.imagePath != nil {
                Button(role: .destructive) {
                    removePhoto()
                } label: {
                    Label("Remove photo", systemImage: "trash")
                }
            }
        }
    }

    @ViewBuilder
    private var signSection: some View {
        Section {
            HStack(spacing: 14) {
                signThumbnail
                VStack(alignment: .leading, spacing: 4) {
                    if let language = draft.signLanguage, draft.signVideoPath != nil {
                        Text("\(language.label) sign attached")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    } else {
                        Text("No sign attached")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text("A sign-language video plays on the tile when no photo is set.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Button {
                showingSignPicker = true
            } label: {
                Label(draft.signVideoPath == nil ? "Choose a sign (Auslan / ASL)" : "Change sign", systemImage: "hand.raised")
            }

            if draft.signVideoPath != nil {
                Button {
                    showingSignThumbnailPicker = true
                } label: {
                    Label(
                        draft.signThumbnailPath == nil ? "Choose thumbnail frame" : "Change thumbnail frame",
                        systemImage: "photo.badge.checkmark"
                    )
                }

                Button(role: .destructive) {
                    removeSign()
                } label: {
                    Label("Remove sign", systemImage: "trash")
                }
            }
        } header: {
            Text("Sign language")
        } footer: {
            Text("Videos are downloaded once from public dictionaries and stored on this device. Pick a thumbnail frame to show a still instead of the looping video — uses less battery.")
        }
    }

    @ViewBuilder
    private var signThumbnail: some View {
        if let filename = draft.signVideoPath, SignVideoStore.exists(filename) {
            SignVideoView(url: SignVideoStore.fileURL(for: filename), videoGravity: .resizeAspectFill)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .allowsHitTesting(false)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.18))
                Image(systemName: "hand.raised")
                    .foregroundStyle(.secondary)
            }
            .frame(width: 64, height: 64)
        }
    }

    @ViewBuilder
    private var photoThumbnail: some View {
        if let filename = draft.imagePath, let image = ImageStore.load(filename) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.18))
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
            .frame(width: 64, height: 64)
        }
    }

    private func loadPhotoPickerItem(_ item: PhotosPickerItem) async {
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await MainActor.run {
                handlePicked(image: image)
            }
        }
    }

    private func handlePicked(image: UIImage) {
        let previousDuringEdit = draft.imagePath
        guard let filename = ImageStore.save(image) else { return }
        draft.imagePath = filename
        if let previousDuringEdit, previousDuringEdit != originalImagePath {
            ImageStore.delete(previousDuringEdit)
        }
    }

    private func removePhoto() {
        if let filename = draft.imagePath, filename != originalImagePath {
            ImageStore.delete(filename)
        }
        draft.imagePath = nil
    }

    private func handlePickedSign(_ selection: SignPickerSelection) {
        let previousDuringEdit = draft.signVideoPath
        draft.signVideoPath = selection.filename
        draft.signLanguage = selection.language
        if let previousDuringEdit, previousDuringEdit != originalSignVideoPath {
            SignVideoStore.delete(previousDuringEdit)
        }
    }

    private func removeSign() {
        if let filename = draft.signVideoPath, filename != originalSignVideoPath {
            SignVideoStore.delete(filename)
        }
        if let thumbPath = draft.signThumbnailPath {
            ImageStore.delete(thumbPath)
        }
        draft.signVideoPath = nil
        draft.signLanguage = nil
        draft.signThumbnailPath = nil
    }

    private func cancel() {
        if let current = draft.imagePath, current != originalImagePath {
            ImageStore.delete(current)
        }
        if let currentSign = draft.signVideoPath, currentSign != originalSignVideoPath {
            SignVideoStore.delete(currentSign)
        }
        dismiss()
    }

    private func save() {
        draft.label = draft.label.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.phrase = draft.phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.symbol = draft.symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.category = draft.category.trimmingCharacters(in: .whitespacesAndNewlines)

        if draft.phrase.isEmpty {
            draft.phrase = draft.label
        }

        if draft.symbol.isEmpty {
            draft.symbol = "💬"
        }

        if draft.category.isEmpty {
            draft.category = AACWord.coreCategory
        }

        if let original = originalImagePath, original != draft.imagePath {
            ImageStore.delete(original)
        }
        if let originalSign = originalSignVideoPath, originalSign != draft.signVideoPath {
            SignVideoStore.delete(originalSign)
        }

        store.upsert(draft)
        dismiss()
    }
}
