import SwiftUI

struct WordTileView: View {
    let word: AACWord
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(word.symbol)
                    .font(.system(size: 40))
                    .minimumScaleFactor(0.6)

                Text(word.label)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black.opacity(0.82))
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
            }
            .frame(maxWidth: .infinity, minHeight: 104)
            .padding(8)
            .background(word.colorName.color)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.black.opacity(0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(word.phrase)
    }
}
