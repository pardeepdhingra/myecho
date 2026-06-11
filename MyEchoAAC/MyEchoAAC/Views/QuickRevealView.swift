import SwiftUI

/// A parent-facing board overlay for progressive reveal — shows all words including hidden ones
/// so parents can tap tiles to toggle visibility without leaving a spatial "hole" for the child.
/// Automatically enables freezeButtonPositions when opened so positions stay locked.
struct QuickRevealView: View {
    @EnvironmentObject private var store: AACStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: String = ""

    private var nonCoreCategories: [String] {
        store.categories.filter { $0 != AACWord.coreCategory }
    }

    private var allInCategory: [AACWord] {
        store.allWords(in: selectedCategory.isEmpty ? nil : selectedCategory)
    }

    private var visibleCount: Int { allInCategory.filter(\.isVisible).count }
    private var totalCount: Int { allInCategory.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !nonCoreCategories.isEmpty {
                    categoryPicker
                }
                statsBar
                Divider()
                grid
            }
            .navigationTitle("Quick Reveal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    freezeToggle
                }
            }
            .onAppear {
                if !store.settings.freezeButtonPositions {
                    store.settings.freezeButtonPositions = true
                }
                selectedCategory = nonCoreCategories.first ?? ""
            }
        }
    }

    // MARK: - Category picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(nonCoreCategories, id: \.self) { cat in
                    Button {
                        selectedCategory = cat
                    } label: {
                        Text(cat)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedCategory == cat ? Color.accentColor : Color.secondary.opacity(0.15))
                            .foregroundStyle(selectedCategory == cat ? Color.white : Color.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    // MARK: - Stats bar

    private var statsBar: some View {
        HStack {
            Label("\(visibleCount) of \(totalCount) visible", systemImage: "eye.fill")
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                let allVisible = allInCategory.allSatisfy(\.isVisible)
                allInCategory.forEach { word in
                    if allVisible ? true : !word.isVisible {
                        store.toggleVisibility(for: word)
                    }
                }
            } label: {
                Text(allInCategory.allSatisfy(\.isVisible) ? "Hide All" : "Show All")
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Grid

    private var grid: some View {
        GeometryReader { geo in
            let cols = max(3, Int(geo.size.width / 110))
            let tileSize = (geo.size.width - CGFloat(cols + 1) * 10) / CGFloat(cols)
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(tileSize), spacing: 10), count: cols),
                    spacing: 10
                ) {
                    ForEach(allInCategory) { word in
                        revealTile(word: word, size: tileSize)
                    }
                }
                .padding(10)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    // MARK: - Individual tile

    private func revealTile(word: AACWord, size: CGFloat) -> some View {
        Button {
            store.toggleVisibility(for: word)
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 4) {
                    WordArtworkView(word: word, size: size * 0.52, cornerRadius: 8)
                        .opacity(word.isVisible ? 1 : 0.35)
                    Text(word.label)
                        .font(.system(size: max(10, size * 0.14), weight: .semibold, design: .rounded))
                        .foregroundStyle(word.isVisible ? Color.black.opacity(0.82) : Color.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                }
                .frame(width: size, height: size)
                .background(store.tileColor(for: word).opacity(word.isVisible ? 1 : 0.25))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    if !word.isVisible {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                            .foregroundStyle(Color.secondary.opacity(0.5))
                    }
                }

                Image(systemName: word.isVisible ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(word.isVisible ? Color.white : Color.secondary)
                    .padding(5)
                    .background(
                        Circle()
                            .fill(word.isVisible ? Color.black.opacity(0.35) : Color.white.opacity(0.75))
                    )
                    .padding(5)
            }
        }
        .buttonStyle(PressableTileStyle())
        .accessibilityLabel("\(word.label), \(word.isVisible ? "visible" : "hidden")")
        .accessibilityHint("Double-tap to \(word.isVisible ? "hide" : "reveal")")
    }

    // MARK: - Freeze toggle

    private var freezeToggle: some View {
        Button {
            store.settings.freezeButtonPositions.toggle()
        } label: {
            Image(systemName: store.settings.freezeButtonPositions ? "lock.fill" : "lock.open")
                .foregroundStyle(store.settings.freezeButtonPositions ? Color.accentColor : Color.secondary)
        }
        .accessibilityLabel(store.settings.freezeButtonPositions ? "Position lock on" : "Position lock off")
        .accessibilityHint("Toggle whether hidden words hold their grid position")
    }
}
