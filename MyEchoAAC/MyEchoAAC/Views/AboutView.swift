import SwiftUI
import UIKit

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                aboutPhoto

                Text("\u{201C}Every child deserves a voice, even if it sounds different.\u{201D}")
                    .font(.system(.title3, design: .serif, weight: .medium))
                    .italic()
                    .foregroundStyle(Color.black.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)

                VStack(alignment: .leading, spacing: 8) {
                    Text("About Vani")
                        .font(.system(.title, design: .rounded, weight: .bold))
                    Text("Built by a father, inspired by his daughter")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Group {
                    paragraph("Vani was created for my daughter Shavya, who is autistic and experiences communication challenges in everyday life.")

                    paragraph("As a parent, I saw how difficult it could be when she wanted to express her needs, feelings, or thoughts but didn\u{2019}t always have the words available at the right moment. We tried different communication tools, but many felt complicated, expensive, or difficult to personalize for real family life.")

                    paragraph("So I decided to build something ourselves.")

                    paragraph("I\u{2019}m a software engineer, but this app was not started as a business idea. It started at home \u{2014} during small daily moments where communication mattered most:")

                    VStack(alignment: .leading, spacing: 6) {
                        bullet("asking for food")
                        bullet("expressing emotions")
                        bullet("choosing activities")
                        bullet("connecting with family")
                    }
                    .padding(.leading, 4)

                    paragraph("Vani is designed to be simple, calm, visual, and easy to use for children and families who rely on AAC support.")

                    paragraph("The goal is not only to help children communicate, but also to help parents feel understood, hopeful, and supported in their journey.")

                    paragraph("Every feature in this app comes from real experiences as a parent raising a child with autism and ADHD.")

                    paragraph("Thank you for being here and for supporting inclusive communication for every child.")
                }

                freeForeverBadge

                creditsSection

                signature
            }
            .padding(24)
        }
        .background(aboutBackground.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private var aboutPhoto: some View {
        if let image = UIImage(named: "AboutPhoto") {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white, lineWidth: 2)
                }
                .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                VStack(spacing: 6) {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Drop your photo at\nAssets.xcassets/AboutPhoto.imageset/photo.jpg")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
        }
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(.system(.body, design: .rounded))
            .foregroundStyle(Color.black.opacity(0.82))
            .lineSpacing(2)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\u{2022}")
                .foregroundStyle(Color.accentColor)
                .font(.body.weight(.bold))
            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.82))
        }
    }

    private var freeForeverBadge: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.85, green: 0.27, blue: 0.47))
                Text("Vani is free, and will always stay free.")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.85))
            }
            Text("No ads. No in-app purchases. No subscriptions. No tracking. Communication shouldn\u{2019}t come with a paywall.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.7))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.95, green: 0.98, blue: 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(red: 0.78, green: 0.88, blue: 1.0), lineWidth: 1.5)
        }
    }

    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Credits")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.7))
            Text("Picture symbols by ARASAAC (arasaac.org), created by the Government of Aragón (Spain) and licensed under Creative Commons BY-NC-SA. Author: Sergio Palao.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("Sign-language videos are sourced from public dictionaries (Auslan Signbank, signasl.org) and remain the property of their creators.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var signature: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\u{2014} Pardeep")
                .font(.system(.headline, design: .rounded, weight: .semibold))
            Text("Father of Shavya")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }

    private var aboutBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.99, blue: 1.0),
                Color(red: 0.95, green: 0.99, blue: 0.97)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
