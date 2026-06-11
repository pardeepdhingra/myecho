import SwiftUI

/// Searchable symbol picker with two tabs:
/// - **Bundled** – the app's built-in ARASAAC symbols (instant, no network needed).
/// - **Online (ARASAAC)** – live search of the full ARASAAC catalog; tapping a result
///   downloads the image and calls `onSelectImage`.
struct SymbolPickerView: View {
    @Environment(\.dismiss) private var dismiss

    /// Called with a bundled symbol asset name (e.g. `sym_apple`) or `nil` (use emoji).
    let onSelect: (String?) -> Void
    /// Called with a locally-saved image filename after an ARASAAC image is downloaded.
    var onSelectImage: ((String) -> Void)? = nil

    @State private var query: String = ""
    @State private var selectedTab: Tab = .bundled

    enum Tab { case bundled, online }

    private let columns = Array(repeating: GridItem(.adaptive(minimum: 78), spacing: 10), count: 1)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Source", selection: $selectedTab) {
                    Text("Bundled").tag(Tab.bundled)
                    Text("Online (ARASAAC)").tag(Tab.online)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)

                if selectedTab == .bundled {
                    bundledGrid
                } else {
                    AARASAACSearchTab(onSelectImage: { path in
                        onSelectImage?(path)
                        dismiss()
                    })
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: selectedTab == .bundled ? "Search symbols" : "Search ARASAAC…")
            .onChange(of: selectedTab) { _, _ in query = "" }
            .navigationTitle("Pick a Symbol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Use emoji instead") {
                        onSelect(nil)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .environment(\.pickerQuery, query)
        }
    }

    private var bundledGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(SymbolLibrary.search(query), id: \.self) { name in
                    Button {
                        onSelect(name)
                        dismiss()
                    } label: {
                        VStack(spacing: 4) {
                            Image(name)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                            Text(SymbolLibrary.label(for: name))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.black.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(SymbolLibrary.label(for: name))
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Environment key for passing searchable query into child views

private struct PickerQueryKey: EnvironmentKey {
    static let defaultValue: String = ""
}

private extension EnvironmentValues {
    var pickerQuery: String {
        get { self[PickerQueryKey.self] }
        set { self[PickerQueryKey.self] = newValue }
    }
}

// MARK: - ARASAAC online search tab

private struct AARASAACSearchTab: View {
    let onSelectImage: (String) -> Void

    @Environment(\.pickerQuery) private var query
    @State private var results: [AARASAACResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var downloadingID: Int?

    private let columns = Array(repeating: GridItem(.adaptive(minimum: 78), spacing: 10), count: 1)

    var body: some View {
        Group {
            if isSearching {
                ProgressView("Searching ARASAAC…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if results.isEmpty {
                Text(query.isEmpty ? "Type above to search 12,000+ ARASAAC symbols" : "No symbols found for \"\(query)\"")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(results) { result in
                            resultCell(result)
                        }
                    }
                    .padding(12)
                }
            }
        }
        .onChange(of: query) { _, newQuery in
            Task { await doSearch(newQuery) }
        }
    }

    @ViewBuilder
    private func resultCell(_ result: AARASAACResult) -> some View {
        let isDownloading = downloadingID == result.id
        Button {
            guard !isDownloading else { return }
            Task { await downloadAndSelect(result) }
        } label: {
            VStack(spacing: 4) {
                AsyncImage(url: AARASAACService.imageURL(for: result.id)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFit()
                    case .failure:
                        Image(systemName: "photo").foregroundStyle(.secondary)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        ProgressView()
                    }
                }
                .frame(width: 56, height: 56)

                if isDownloading {
                    ProgressView()
                        .frame(height: 12)
                } else {
                    Text(result.keyword)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color.black.opacity(isDownloading ? 0.06 : 0.03))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDownloading)
        .accessibilityLabel(result.keyword)
    }

    private func doSearch(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            errorMessage = nil
            return
        }
        isSearching = true
        errorMessage = nil
        do {
            results = try await AARASAACService.search(trimmed)
        } catch {
            results = []
            errorMessage = "Search failed. Check your connection and try again."
        }
        isSearching = false
    }

    private func downloadAndSelect(_ result: AARASAACResult) async {
        downloadingID = result.id
        do {
            let path = try await AARASAACService.downloadImage(id: result.id)
            downloadingID = nil
            onSelectImage(path)
        } catch {
            downloadingID = nil
        }
    }
}
