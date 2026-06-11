import SwiftUI

struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "waveform.and.mic",
            iconColor: Color.accentColor,
            title: "Welcome to वाणी",
            subtitle: "Vani — Voice",
            body: "A communication board designed for children who use AAC.\nEverything works offline, right on your device.",
            isWelcome: true
        ),
        OnboardingPage(
            icon: "hand.tap.fill",
            iconColor: .blue,
            title: "Tap a Tile",
            subtitle: "Build sentences, one word at a time",
            body: "Each tile is spoken aloud and added to the message bar. Tap Speak to say the full sentence with a natural pause.",
            isWelcome: false
        ),
        OnboardingPage(
            icon: "photo.on.rectangle.angled",
            iconColor: .purple,
            title: "Make It Personal",
            subtitle: "Real photos and sign language videos",
            body: "Replace any symbol with a photo from the camera or library. Attach sign language videos so every tile teaches as it communicates.",
            isWelcome: false
        ),
        OnboardingPage(
            icon: "slider.horizontal.3",
            iconColor: .green,
            title: "Parent Settings",
            subtitle: "Customise everything from one place",
            body: "Add words, adjust visibility, set a PIN for privacy, and organise multiple boards for home, school, and therapy.",
            isWelcome: false
        ),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: page)

            bottomControls
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Page

    private func pageView(_ p: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            Spacer()
            if p.isWelcome {
                welcomeHeader
            } else {
                featureIcon(p)
            }
            Spacer().frame(height: 28)
            VStack(spacing: 8) {
                Text(p.title)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(p.subtitle)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer().frame(height: 16)
            Text(p.body)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 36)
            Spacer()
            Spacer().frame(height: 120)
        }
    }

    private var welcomeHeader: some View {
        VStack(spacing: 16) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                .accessibilityHidden(true)
        }
    }

    private func featureIcon(_ p: OnboardingPage) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(p.iconColor.opacity(0.12))
                .frame(width: 100, height: 100)
            Image(systemName: p.icon)
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(p.iconColor)
        }
    }

    // MARK: - Bottom controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            pageDots

            if page < pages.count - 1 {
                HStack {
                    Button("Skip") {
                        dismiss()
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        withAnimation { page += 1 }
                    } label: {
                        Label("Next", systemImage: "arrow.right")
                            .labelStyle(.titleAndIcon)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 13)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button {
                    dismiss()
                } label: {
                    Text("Get Started")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var pageDots: some View {
        HStack(spacing: 7) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Color.accentColor : Color.secondary.opacity(0.35))
                    .frame(width: i == page ? 20 : 7, height: 7)
                    .animation(.spring(response: 0.3), value: page)
            }
        }
    }
}

// MARK: - Model

private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let body: String
    let isWelcome: Bool
}
