import Foundation

@MainActor
final class SceneStore: ObservableObject {
    @Published var scenes: [AACScene] {
        didSet { save() }
    }

    private let key = "vani.scenes.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: "vani.scenes.v1"),
           let stored = try? JSONDecoder().decode([AACScene].self, from: data) {
            scenes = stored
        } else {
            scenes = []
        }
    }

    var visibleScenes: [AACScene] {
        scenes.filter(\.isVisible).sorted { $0.position < $1.position }
    }

    func addScene(name: String) {
        let pos = (scenes.map(\.position).max() ?? -1) + 1
        scenes.append(AACScene(name: name, position: pos))
    }

    func upsert(_ scene: AACScene) {
        if let i = scenes.firstIndex(where: { $0.id == scene.id }) {
            scenes[i] = scene
        } else {
            scenes.append(scene)
        }
    }

    func deleteScene(_ scene: AACScene) {
        scenes.removeAll { $0.id == scene.id }
        if let path = scene.imagePath {
            ImageStore.delete(path)
        }
    }

    func toggleVisibility(_ scene: AACScene) {
        guard let i = scenes.firstIndex(where: { $0.id == scene.id }) else { return }
        scenes[i].isVisible.toggle()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(scenes) {
            defaults.set(data, forKey: key)
        }
    }
}
