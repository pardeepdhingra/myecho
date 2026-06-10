import SwiftUI
import UIKit

/// A folder tile on the folder ("Motor Plan") home page. Tapping it opens that category's fixed grid.
/// Deliberately rendered as a **bold, solid-colour** tile (white label + folder badge) so it stands out
/// clearly from the lighter word tiles — folders *navigate*, words *speak*. The `icon` may be an emoji
/// or a bundled picture-symbol asset name (`sym_…`).
struct FolderTileView: View {
    let title: String
    let icon: String
    let color: Color
    var scale: Double = 1.0
    /// Kept for call-site compatibility; folders always use the bold look regardless of board tile style.
    var style: TileStyle = .filled
    let action: () -> Void

    private var clampedScale: Double { min(max(scale, 0.7), 1.8) }

    var body: some View {
        Button {
            Haptics.actionTap()
            action()
        } label: {
            VStack(spacing: 6 * clampedScale) {
                ZStack(alignment: .bottomTrailing) {
                    iconView
                        .padding(6 * clampedScale)
                        .background(.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 8 * clampedScale, style: .continuous))
                    Image(systemName: "folder.fill")
                        .font(.system(size: 14 * clampedScale, weight: .bold))
                        .foregroundStyle(color)
                        .padding(3 * clampedScale)
                        .background(.white)
                        .clipShape(Circle())
                        .offset(x: 5 * clampedScale, y: 4 * clampedScale)
                }

                Text(title)
                    .font(.system(size: 16 * clampedScale, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(8 * clampedScale)
            .background(
                LinearGradient(
                    colors: [boldColor, boldColor.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8 * clampedScale, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8 * clampedScale, style: .continuous)
                    .stroke(.white.opacity(0.7), lineWidth: 1.5)
            }
            .shadow(color: boldColor.opacity(0.35), radius: 5, y: 2)
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(PressableTileStyle())
        .accessibilityLabel("\(title) folder")
        .accessibilityHint("Opens the \(title) words")
    }

    /// A deeper, saturated version of the (pastel) category colour so the folder reads as solid colour.
    private var boldColor: Color {
        let ui = UIColor(color)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return Color(hue: Double(h), saturation: Double(min(s * 1.7 + 0.12, 1.0)),
                         brightness: Double(b * 0.82))
        }
        return color
    }

    @ViewBuilder
    private var iconView: some View {
        if icon.hasPrefix(SymbolLibrary.assetPrefix), SymbolLibrary.exists(icon) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 38 * clampedScale, height: 38 * clampedScale)
        } else {
            Text(icon)
                .font(.system(size: 34 * clampedScale))
                .minimumScaleFactor(0.5)
        }
    }
}
