import PhotosUI
import SwiftUI
import UIKit

struct EditWordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AACStore

    @State private var draft: AACWord
    @State private var originalImagePath: String?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingEmojiPicker = false
    @State private var showCustomSymbol = false
    @State private var isAddingNewCategory = false
    @State private var newCategoryText: String = ""

    init(word: AACWord) {
        _draft = State(initialValue: word)
        _originalImagePath = State(initialValue: word.imagePath)
    }

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Word") {
                    TextField("Label", text: $draft.label)
                    TextField("Spoken phrase", text: $draft.phrase)
                    symbolRow
                    if showCustomSymbol {
                        TextField("Custom symbol", text: $draft.symbol)
                    }
                    categoryRow
                }

                photoSection

                Section("Board") {
                    Picker("Color", selection: $draft.colorName) {
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

                    Toggle("Visible on kid screen", isOn: $draft.isVisible)
                    Toggle("Favorite (shows in ★ Favorites)", isOn: $draft.isFavorite)
                }

                Section("Preview") {
                    WordTileView(word: draft, action: {}, scale: store.settings.tileScale)
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
            .sheet(isPresented: $showingCamera) {
                CameraPicker { image in
                    handlePicked(image: image)
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView { emoji in
                    draft.symbol = emoji
                }
            }
        }
    }

    private var existingCategories: [String] {
        let all = Set(store.words.map(\.category)).filter { !$0.isEmpty }
        return all.sorted()
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

    private func cancel() {
        if let current = draft.imagePath, current != originalImagePath {
            ImageStore.delete(current)
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
            draft.category = "Home"
        }

        if let original = originalImagePath, original != draft.imagePath {
            ImageStore.delete(original)
        }

        store.upsert(draft)
        dismiss()
    }
}
