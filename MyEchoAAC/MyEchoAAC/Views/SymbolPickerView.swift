import SwiftUI

/// A searchable grid of the bundled ARASAAC picture symbols. Returns the chosen asset name (e.g.
/// `sym_apple`), or nil if the parent clears the symbol (falling back to the emoji).
struct SymbolPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String?) -> Void

    @State private var query: String = ""

    private let columns = Array(repeating: GridItem(.adaptive(minimum: 78), spacing: 10), count: 1)

    private var results: [String] {
        SymbolLibrary.search(query)
    }

    @ViewBuilder
    private func cell(_ name: String) -> some View {
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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(results, id: \.self) { name in
                            cell(name)
                        }
                    }
                    .padding(12)
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search symbols")
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
        }
    }
}
