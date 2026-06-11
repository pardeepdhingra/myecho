import Testing
@testable import MyEchoAAC

@MainActor @Suite("SceneStore")
struct SceneStoreTests {

    // MARK: - Initialization

    @Test("SceneStore starts empty")
    func startsEmpty() {
        let defaults = makeIsolatedDefaults()
        let store = SceneStore(defaults: defaults)
        #expect(store.scenes.isEmpty)
    }

    // MARK: - Add / delete

    @Test("addScene appends a scene")
    func addSceneAppends() {
        let defaults = makeIsolatedDefaults()
        let store = SceneStore(defaults: defaults)
        store.addScene(name: "Kitchen")
        #expect(store.scenes.count == 1)
        #expect(store.scenes.first?.name == "Kitchen")
    }

    @Test("addScene defaults to visible")
    func addSceneDefaultsVisible() {
        let defaults = makeIsolatedDefaults()
        let store = SceneStore(defaults: defaults)
        store.addScene(name: "Kitchen")
        #expect(store.scenes.first?.isVisible == true)
    }

    @Test("deleteScene removes it")
    func deleteSceneRemoves() {
        let defaults = makeIsolatedDefaults()
        let store = SceneStore(defaults: defaults)
        store.addScene(name: "Kitchen")
        let scene = store.scenes.first!
        store.deleteScene(scene)
        #expect(store.scenes.isEmpty)
    }

    // MARK: - Update

    @Test("updateScene persists name change")
    func updateSceneName() {
        let defaults = makeIsolatedDefaults()
        let store = SceneStore(defaults: defaults)
        store.addScene(name: "Kitchen")
        var scene = store.scenes.first!
        scene.name = "Bathroom"
        store.upsert(scene)
        #expect(store.scenes.first?.name == "Bathroom")
    }

    @Test("toggleVisibility flips isVisible")
    func toggleVisibility() {
        let defaults = makeIsolatedDefaults()
        let store = SceneStore(defaults: defaults)
        store.addScene(name: "Test")
        let scene = store.scenes.first!
        store.toggleVisibility(scene)
        #expect(store.scenes.first?.isVisible == false)
        store.toggleVisibility(store.scenes.first!)
        #expect(store.scenes.first?.isVisible == true)
    }

    // MARK: - Hotspots

    @Test("addHotspot appends to correct scene")
    func addHotspotAppendsToScene() {
        let defaults = makeIsolatedDefaults()
        let store = SceneStore(defaults: defaults)
        store.addScene(name: "Kitchen")
        var scene = store.scenes.first!
        let hotspot = AACSceneHotspot(
            label: "fridge", phrase: "fridge", symbol: "🧊",
            normalizedX: 0.3, normalizedY: 0.5
        )
        scene.hotspots.append(hotspot)
        store.upsert(scene)
        #expect(store.scenes.first?.hotspots.count == 1)
        #expect(store.scenes.first?.hotspots.first?.label == "fridge")
    }

    @Test("removeHotspot removes it from scene")
    func removeHotspot() {
        let defaults = makeIsolatedDefaults()
        let store = SceneStore(defaults: defaults)
        store.addScene(name: "Kitchen")
        var scene = store.scenes.first!
        let hotspot = AACSceneHotspot(
            label: "fridge", phrase: "fridge", symbol: "🧊",
            normalizedX: 0.3, normalizedY: 0.5
        )
        scene.hotspots.append(hotspot)
        store.upsert(scene)
        var updated = store.scenes.first!
        updated.hotspots.removeAll { $0.id == hotspot.id }
        store.upsert(updated)
        #expect(store.scenes.first?.hotspots.isEmpty == true)
    }

    // MARK: - Persistence

    @Test("scenes persist across instances")
    func scenesPersist() {
        let defaults = makeIsolatedDefaults()
        let store1 = SceneStore(defaults: defaults)
        store1.addScene(name: "Bedroom")
        let store2 = SceneStore(defaults: defaults)
        #expect(store2.scenes.contains(where: { $0.name == "Bedroom" }))
    }

    @Test("visible scenes filters correctly")
    func visibleScenes() {
        let defaults = makeIsolatedDefaults()
        let store = SceneStore(defaults: defaults)
        store.addScene(name: "Kitchen")
        store.addScene(name: "Bedroom")
        store.toggleVisibility(store.scenes.last!)
        #expect(store.visibleScenes.count == 1)
        #expect(store.visibleScenes.first?.name == "Kitchen")
    }
}
