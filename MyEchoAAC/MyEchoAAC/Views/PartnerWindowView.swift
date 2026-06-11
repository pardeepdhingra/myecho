import SwiftUI

/// Full-screen overlay showing the current message in large rotated text so the
/// communication partner sitting across from the child can read it without
/// turning the iPad.
struct PartnerWindowView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()

                Text(message)
                    .font(.system(size: adaptiveFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.4)
                    .lineLimit(4)
                    .padding(.horizontal, 32)
                    .rotationEffect(.degrees(180))

                Spacer()

                Text("Tap anywhere to close")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .rotationEffect(.degrees(180))
                    .padding(.bottom, 24)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onDismiss() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Partner window: \(message)")
        .accessibilityHint("Tap to close")
        .preferredColorScheme(.dark)
    }

    private var adaptiveFontSize: CGFloat {
        switch message.count {
        case ..<20: return 96
        case ..<40: return 72
        case ..<70: return 56
        default: return 44
        }
    }
}
