import SwiftUI

/// Single source of truth for a word's artwork in the child's UI.
///
/// Priority order: custom photo → user sign thumbnail (static) → auto sign thumbnail (static) → sign video (looping) → picture symbol → emoji.
/// The auto-thumbnail is generated from the sign video's final frame at download time, avoiding video
/// decoding on every tile render when no user-chosen frame has been set (saves CPU / battery).
/// Use this everywhere a word's image appears so the child always sees the exact same artwork
/// regardless of whether it's on the main tile, the message bar chip, the suggestion strip, etc.
struct WordArtworkView: View {
    let word: AACWord
    /// Square dimension for the artwork. The view constrains itself to size × size.
    var size: CGFloat = 44
    /// Corner radius applied to photos and sign videos. Defaults to ~18 % of size.
    var cornerRadius: CGFloat? = nil

    private var r: CGFloat { cornerRadius ?? (size * 0.18) }

    var body: some View {
        Group {
            if let filename = word.imagePath, let image = ImageStore.load(filename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
            } else if let thumbFilename = word.signThumbnailPath, let thumb = ImageStore.load(thumbFilename) {
                Image(uiImage: thumb)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
            } else if let signFilename = word.signVideoPath,
                      let autoThumb = SignVideoStore.loadThumbnail(for: signFilename) {
                Image(uiImage: autoThumb)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
            } else if let signFilename = word.signVideoPath, SignVideoStore.exists(signFilename) {
                SignVideoView(url: SignVideoStore.fileURL(for: signFilename),
                              videoGravity: .resizeAspectFill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
                    .allowsHitTesting(false)
            } else if let symbolName = word.symbolName, SymbolLibrary.exists(symbolName) {
                Image(symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                Text(word.symbol)
                    .font(.system(size: size * 0.65))
                    .minimumScaleFactor(0.5)
                    .frame(width: size, height: size)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
