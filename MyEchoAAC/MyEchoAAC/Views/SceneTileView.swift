import SwiftUI

/// Kid-board tile for a visual scene: shows the scene's photo as the background (cropped square)
/// so the child recognises it at a glance. Falls back to the emoji icon when no photo is set.
struct SceneTileView: View {
    let scene: AACScene
    var scale: Double = 1.0
    let action: () -> Void

    private var clampedScale: Double { min(max(scale, 0.7), 1.8) }
    private static let accentColor = Color(red: 0.25, green: 0.62, blue: 0.50)

    var body: some View {
        Button {
            Haptics.actionTap()
            action()
        } label: {
            ZStack(alignment: .bottom) {
                photoBackground
                    .clipShape(RoundedRectangle(cornerRadius: 8 * clampedScale, style: .continuous))

                // Bottom gradient + label
                VStack(spacing: 0) {
                    Spacer()
                    LinearGradient(
                        colors: [.black.opacity(0.65), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 48 * clampedScale)
                }

                Text(scene.name)
                    .font(.system(size: 15 * clampedScale, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
                    .padding(.horizontal, 6 * clampedScale)
                    .padding(.bottom, 8 * clampedScale)
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 12 * clampedScale, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(4 * clampedScale)
                    .background(Self.accentColor)
                    .clipShape(Circle())
                    .padding(5 * clampedScale)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8 * clampedScale, style: .continuous)
                    .stroke(.white.opacity(0.5), lineWidth: 1.5)
            }
            .shadow(color: Self.accentColor.opacity(0.35), radius: 5, y: 2)
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(PressableTileStyle())
        .accessibilityLabel("\(scene.name) scene")
        .accessibilityHint("Opens the \(scene.name) visual scene")
    }

    @ViewBuilder
    private var photoBackground: some View {
        if let path = scene.imagePath, let img = ImageStore.load(path) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            ZStack {
                LinearGradient(
                    colors: [Self.accentColor, Self.accentColor.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text("🖼️")
                    .font(.system(size: 36 * clampedScale))
            }
        }
    }
}
