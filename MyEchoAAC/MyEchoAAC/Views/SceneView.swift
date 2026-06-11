import SwiftUI

/// Kid-facing visual scene: a full-screen photo with circular hotspot buttons.
/// Tapping a hotspot speaks the word and adds it to the message bar.
struct SceneView: View {
    let scene: AACScene
    let onAddWord: (AACWord) -> Void

    @EnvironmentObject private var speech: SpeechService
    @EnvironmentObject private var store: AACStore
    @Environment(\.dismiss) private var dismiss

    @State private var image: UIImage?
    @State private var tappedHotspot: UUID?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .overlay {
                            GeometryReader { imgGeo in
                                let displaySize = fittedSize(image: img, in: imgGeo.size)
                                let offsetX = (imgGeo.size.width - displaySize.width) / 2
                                let offsetY = (imgGeo.size.height - displaySize.height) / 2

                                ForEach(scene.hotspots) { hotspot in
                                    hotspotButton(hotspot,
                                                  displaySize: displaySize,
                                                  offset: CGPoint(x: offsetX, y: offsetY))
                                }
                            }
                        }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text(scene.name)
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                // Scene name label at top
                VStack {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .shadow(color: .black.opacity(0.4), radius: 3)
                        }
                        .buttonStyle(.plain)
                        .padding(16)
                        .accessibilityLabel("Close scene")

                        Spacer()

                        Text(scene.name)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.6), radius: 4)
                            .padding(.trailing, 52)
                    }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if let path = scene.imagePath {
                image = ImageStore.load(path)
            }
        }
    }

    // MARK: - Hotspot button

    private func hotspotButton(_ hotspot: AACSceneHotspot, displaySize: CGSize, offset: CGPoint) -> some View {
        let cx = offset.x + hotspot.normalizedX * displaySize.width
        let cy = offset.y + hotspot.normalizedY * displaySize.height
        let r = hotspot.radius * displaySize.width
        let isActive = tappedHotspot == hotspot.id

        return Button {
            let word = AACWord(
                label: hotspot.label,
                phrase: hotspot.phrase,
                symbol: hotspot.symbol,
                category: "Scene",
                colorName: .blue,
                position: 0
            )
            speech.speak(hotspot.phrase, settings: store.settings)
            onAddWord(word)
            Haptics.actionTap()
            tappedHotspot = hotspot.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                tappedHotspot = nil
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isActive ? Color.yellow : Color.white.opacity(0.88))
                    .frame(width: r * 2, height: r * 2)
                    .shadow(color: .black.opacity(0.4), radius: 4)
                    .scaleEffect(isActive ? 1.15 : 1)
                    .animation(.spring(response: 0.2), value: isActive)

                VStack(spacing: 2) {
                    Text(hotspot.symbol)
                        .font(.system(size: r * 0.7))
                        .minimumScaleFactor(0.5)
                    Text(hotspot.label)
                        .font(.system(size: max(9, r * 0.3), weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
        .buttonStyle(.plain)
        .position(x: cx, y: cy)
        .accessibilityLabel(hotspot.label)
        .accessibilityHint("Double-tap to speak and add to message")
    }

    // MARK: - Fitted size helper

    private func fittedSize(image: UIImage, in container: CGSize) -> CGSize {
        let imageAspect = image.size.width / image.size.height
        let containerAspect = container.width / container.height
        if imageAspect > containerAspect {
            return CGSize(width: container.width, height: container.width / imageAspect)
        } else {
            return CGSize(width: container.height * imageAspect, height: container.height)
        }
    }
}
