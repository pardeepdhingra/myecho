import SwiftUI
import UIKit

struct WordTileView: View {
    let word: AACWord
    let action: () -> Void
    var scale: Double = 1.0

    private var clampedScale: Double { min(max(scale, 0.7), 1.8) }

    var body: some View {
        Button {
            Haptics.tileTap()
            action()
        } label: {
            VStack(spacing: 8 * clampedScale) {
                tileImage

                Text(word.label)
                    .font(.system(size: 18 * clampedScale, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black.opacity(0.82))
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
            }
            .frame(maxWidth: .infinity, minHeight: 104 * clampedScale)
            .padding(8 * clampedScale)
            .background(
                LinearGradient(
                    colors: [
                        word.colorName.color,
                        word.colorName.color.opacity(0.78)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8 * clampedScale, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8 * clampedScale, style: .continuous)
                    .stroke(.black.opacity(0.12), lineWidth: 1)
            }
            .overlay(alignment: .topTrailing) {
                if word.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12 * clampedScale, weight: .bold))
                        .foregroundStyle(.yellow.shadow(.drop(color: .black.opacity(0.3), radius: 1)))
                        .padding(6 * clampedScale)
                }
            }
            .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
        }
        .buttonStyle(PressableTileStyle())
        .accessibilityLabel(word.phrase)
    }

    @ViewBuilder
    private var tileImage: some View {
        if let filename = word.imagePath, let image = ImageStore.load(filename) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 56 * clampedScale, height: 56 * clampedScale)
                .clipShape(RoundedRectangle(cornerRadius: 8 * clampedScale, style: .continuous))
        } else {
            Text(word.symbol)
                .font(.system(size: 42 * clampedScale))
                .minimumScaleFactor(0.5)
        }
    }
}

struct PressableTileStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
