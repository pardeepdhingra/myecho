import SwiftUI
import PhotosUI

/// Parent-facing editor to create / configure visual scenes.
/// Parents pick a photo, then tap directly on the image to place hotspots.
struct SceneEditorView: View {
    var scene: AACScene
    let onSave: (AACScene) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var editedScene: AACScene
    @State private var image: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var editingHotspot: AACSceneHotspot?
    @State private var showingHotspotEditor = false
    @State private var pendingTapLocation: CGPoint?

    init(scene: AACScene, onSave: @escaping (AACScene) -> Void) {
        self.scene = scene
        self.onSave = onSave
        _editedScene = State(initialValue: scene)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sceneNameField
                Divider()
                imageArea
                Divider()
                hotspotList
            }
            .navigationTitle(editedScene.name.isEmpty ? "New Scene" : editedScene.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(editedScene)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingHotspotEditor) {
                if let hs = editingHotspot {
                    HotspotEditorSheet(hotspot: hs) { updated in
                        if let i = editedScene.hotspots.firstIndex(where: { $0.id == updated.id }) {
                            editedScene.hotspots[i] = updated
                        }
                    }
                }
            }
        }
        .onAppear {
            if let path = editedScene.imagePath {
                image = ImageStore.load(path)
            }
        }
        .onChange(of: pickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    if let old = editedScene.imagePath { ImageStore.delete(old) }
                    editedScene.imagePath = ImageStore.save(img)
                    image = img
                }
            }
        }
    }

    // MARK: - Name field

    private var sceneNameField: some View {
        HStack {
            TextField("Scene name", text: $editedScene.name)
                .font(.system(.body, design: .rounded))
                .textInputAutocapitalization(.words)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Image area (tap to place hotspots)

    private var imageArea: some View {
        ZStack {
            if let img = image {
                GeometryReader { geo in
                    let displaySize = fittedSize(image: img, in: geo.size)
                    let offsetX = (geo.size.width - displaySize.width) / 2
                    let offsetY = (geo.size.height - displaySize.height) / 2

                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .overlay {
                            // Tap gesture to place hotspots
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture { location in
                                    let nx = (location.x - offsetX) / displaySize.width
                                    let ny = (location.y - offsetY) / displaySize.height
                                    guard nx >= 0, nx <= 1, ny >= 0, ny <= 1 else { return }
                                    let hs = AACSceneHotspot(
                                        label: "Tap to name",
                                        phrase: "Tap to name",
                                        symbol: "📍",
                                        normalizedX: nx,
                                        normalizedY: ny
                                    )
                                    editedScene.hotspots.append(hs)
                                    editingHotspot = hs
                                    showingHotspotEditor = true
                                }

                            // Render existing hotspots
                            ForEach(editedScene.hotspots) { hotspot in
                                hotspotPin(hotspot, displaySize: displaySize,
                                           offset: CGPoint(x: offsetX, y: offsetY))
                            }
                        }
                }
            } else {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 52))
                            .foregroundStyle(Color.accentColor)
                        Text("Tap to choose a scene photo")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: .secondarySystemBackground))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 280)
        .background(Color.black)
        .overlay(alignment: .bottomTrailing) {
            if image != nil {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.callout.weight(.semibold))
                        .padding(10)
                        .background(Color.black.opacity(0.55))
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(10)
            }
        }
    }

    // MARK: - Hotspot pin in editor

    private func hotspotPin(_ hs: AACSceneHotspot, displaySize: CGSize, offset: CGPoint) -> some View {
        let cx = offset.x + hs.normalizedX * displaySize.width
        let cy = offset.y + hs.normalizedY * displaySize.height

        return Button {
            editingHotspot = hs
            showingHotspotEditor = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 36, height: 36)
                    .shadow(color: .black.opacity(0.4), radius: 3)
                Text(hs.symbol)
                    .font(.system(size: 18))
            }
        }
        .buttonStyle(.plain)
        .position(x: cx, y: cy)
        .contextMenu {
            Button(role: .destructive) {
                editedScene.hotspots.removeAll { $0.id == hs.id }
            } label: {
                Label("Remove Hotspot", systemImage: "trash")
            }
        }
        .accessibilityLabel("Edit hotspot: \(hs.label)")
    }

    // MARK: - Hotspot list

    private var hotspotList: some View {
        List {
            if editedScene.hotspots.isEmpty {
                Text(image == nil ? "Add a photo first, then tap to place hotspots." : "Tap anywhere on the photo to add a hotspot.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(editedScene.hotspots) { hs in
                    HStack(spacing: 12) {
                        Text(hs.symbol).font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(hs.label)
                                .font(.system(.body, design: .rounded, weight: .semibold))
                            Text(hs.phrase)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingHotspot = hs
                        showingHotspotEditor = true
                    }
                }
                .onDelete { offsets in
                    editedScene.hotspots.remove(atOffsets: offsets)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Helpers

    private func fittedSize(image: UIImage, in container: CGSize) -> CGSize {
        guard container.width > 0, container.height > 0 else { return .zero }
        let imageAspect = image.size.width / image.size.height
        let containerAspect = container.width / container.height
        if imageAspect > containerAspect {
            return CGSize(width: container.width, height: container.width / imageAspect)
        } else {
            return CGSize(width: container.height * imageAspect, height: container.height)
        }
    }
}

// MARK: - Hotspot editor sheet

private struct HotspotEditorSheet: View {
    var hotspot: AACSceneHotspot
    let onSave: (AACSceneHotspot) -> Void

    @State private var label: String
    @State private var phrase: String
    @State private var symbol: String
    @Environment(\.dismiss) private var dismiss

    init(hotspot: AACSceneHotspot, onSave: @escaping (AACSceneHotspot) -> Void) {
        self.hotspot = hotspot
        self.onSave = onSave
        _label = State(initialValue: hotspot.label == "Tap to name" ? "" : hotspot.label)
        _phrase = State(initialValue: hotspot.phrase == "Tap to name" ? "" : hotspot.phrase)
        _symbol = State(initialValue: hotspot.symbol == "📍" ? "" : hotspot.symbol)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Label (shown on hotspot)") {
                    TextField("e.g. fridge", text: $label)
                        .autocorrectionDisabled()
                }
                Section("Spoken phrase") {
                    TextField("e.g. fridge", text: $phrase)
                        .autocorrectionDisabled()
                    Text("Leave blank to use the label.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Symbol / emoji") {
                    TextField("e.g. 🧊", text: $symbol)
                }
            }
            .navigationTitle("Edit Hotspot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        let trimLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimLabel.isEmpty else { return }
                        let trimPhrase = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
                        var updated = hotspot
                        updated.label = trimLabel
                        updated.phrase = trimPhrase.isEmpty ? trimLabel : trimPhrase
                        updated.symbol = trimSymbol.isEmpty ? "📍" : trimSymbol
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
