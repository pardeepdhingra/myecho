import SwiftUI

/// Parent-facing list of visual scenes — create, edit, delete scenes
/// from the Parent Mode "Scenes" tab.
struct SceneListView: View {
    @EnvironmentObject private var sceneStore: SceneStore
    @State private var editingScene: AACScene?
    @State private var showingAddSheet = false
    @State private var newSceneName = ""

    var body: some View {
        List {
            if sceneStore.scenes.isEmpty {
                emptyState
            } else {
                ForEach(sceneStore.scenes) { scene in
                    sceneRow(scene)
                }
                .onDelete { offsets in
                    offsets.map { sceneStore.scenes[$0] }.forEach(sceneStore.deleteScene)
                }
            }
        }
        .navigationTitle("Scenes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newSceneName = ""
                    showingAddSheet = true
                } label: {
                    Label("Add Scene", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            addSheet
        }
        .sheet(item: $editingScene) { scene in
            SceneEditorView(scene: scene) { updated in
                sceneStore.upsert(updated)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("No scenes yet")
                .font(.system(.headline, design: .rounded))
            Text("Add a scene photo and place tappable hotspots on it for early communicators.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    }

    // MARK: - Scene row

    private func sceneRow(_ scene: AACScene) -> some View {
        HStack(spacing: 14) {
            sceneThumbnail(scene)

            VStack(alignment: .leading, spacing: 3) {
                Text(scene.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                Text("\(scene.hotspots.count) hotspot\(scene.hotspots.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                sceneStore.toggleVisibility(scene)
            } label: {
                Image(systemName: scene.isVisible ? "eye" : "eye.slash")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(scene.isVisible ? "Hide scene" : "Show scene")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingScene = scene
        }
    }

    private func sceneThumbnail(_ scene: AACScene) -> some View {
        Group {
            if let path = scene.imagePath, let img = ImageStore.load(path) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 56, height: 56)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Add sheet

    private var addSheet: some View {
        NavigationStack {
            Form {
                Section("Scene name") {
                    TextField("e.g. Kitchen, Bedroom", text: $newSceneName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("New Scene")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showingAddSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        let name = newSceneName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        sceneStore.addScene(name: name)
                        if let scene = sceneStore.scenes.last {
                            showingAddSheet = false
                            editingScene = scene
                        }
                    }
                    .disabled(newSceneName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
