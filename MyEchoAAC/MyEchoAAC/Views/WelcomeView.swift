import SwiftUI

struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 22) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text("Welcome to वाणी")
                    .font(.system(.title, design: .rounded, weight: .bold))
                Text("Vani — Voice")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                row(icon: "hand.tap", title: "Tap a tile", subtitle: "Each word is spoken aloud and added to the message bar.")
                row(icon: "speaker.wave.2.fill", title: "Tap Speak", subtitle: "Speaks the whole sentence with a natural pause.")
                row(icon: "slider.horizontal.3", title: "Parent settings", subtitle: "Tap the slider icon top-right. Set a 4-digit PIN the first time.")
                row(icon: "photo.on.rectangle", title: "Use real photos", subtitle: "Parent mode → Words → tap a word → add a photo from the library or camera.")
                row(icon: "quote.bubble.fill", title: "Quick phrases", subtitle: "One-tap chips for daily sentences like 'I want water'.")
            }
            .padding(.horizontal, 8)

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Text("Get Started")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
    }

    private func row(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
