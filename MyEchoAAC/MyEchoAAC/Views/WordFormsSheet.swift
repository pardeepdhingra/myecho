import SwiftUI

/// Bottom sheet showing the alternative word forms (e.g. eating / ate / eats) for a tile.
/// Tapping a form chip adds that form to the message bar exactly like tapping the tile itself.
struct WordFormsSheet: View {
    let word: AACWord
    let tileColor: Color
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Forms of \"\(word.label)\"")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)

                FlowLayout(spacing: 10) {
                    ForEach(word.wordForms, id: \.self) { form in
                        Button {
                            onSelect(form)
                            dismiss()
                        } label: {
                            Text(form)
                                .font(.system(.title2, design: .rounded, weight: .semibold))
                                .foregroundStyle(Color.black.opacity(0.85))
                                .padding(.horizontal, 22)
                                .padding(.vertical, 14)
                                .background(tileColor)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                }
                        }
                        .buttonStyle(PressableTileStyle())
                        .accessibilityLabel(form)
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle(word.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(240), .medium])
        .presentationDragIndicator(.visible)
    }
}

/// Simple row-wrapping layout for the form chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
