import SwiftUI
import UIKit

struct WordTileView: View {
    let word: AACWord
    let action: () -> Void
    var scale: Double = 1.0
    /// Optional background override (e.g. the word's category color). Falls back to the word's own color.
    var backgroundColor: Color? = nil

    private var clampedScale: Double { min(max(scale, 0.7), 1.8) }
    private var tileColor: Color { backgroundColor ?? word.colorName.color }

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(8 * clampedScale)
            .background(
                LinearGradient(
                    colors: [
                        tileColor,
                        tileColor.opacity(0.78)
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
            // Keep tiles square at every column count: height follows the column width
            // instead of a fixed value, so 9–12 columns no longer turn into tall rectangles.
            .aspectRatio(1, contentMode: .fit)
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
        } else if let signFilename = word.signVideoPath, SignVideoStore.exists(signFilename) {
            SignVideoView(url: SignVideoStore.fileURL(for: signFilename), videoGravity: .resizeAspectFill)
                .frame(width: 56 * clampedScale, height: 56 * clampedScale)
                .clipShape(RoundedRectangle(cornerRadius: 8 * clampedScale, style: .continuous))
                .allowsHitTesting(false)
        } else {
            Text(word.symbol)
                .font(.system(size: 42 * clampedScale))
                .minimumScaleFactor(0.5)
        }
    }
}

/// An empty grid cell shown when "Freeze button positions" is on and a tile's word isn't in the
/// selected category. Matches `WordTileView`'s square footprint exactly so the grid stays aligned.
struct BlankTileView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.black.opacity(0.035))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
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
