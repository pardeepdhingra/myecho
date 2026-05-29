import SwiftUI

struct EmojiPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String) -> Void

    @State private var selectedCategory: EmojiCategory = .faces

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 6)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(EmojiCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(selectedCategory.emoji, id: \.self) { emoji in
                            Button {
                                onSelect(emoji)
                                dismiss()
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 36))
                                    .frame(width: 50, height: 50)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(emoji)
                        }
                    }
                    .padding(12)
                }
            }
            .navigationTitle("Pick an Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

enum EmojiCategory: String, CaseIterable, Identifiable {
    case faces
    case people
    case food
    case animals
    case objects
    case activity
    case places

    var id: String { rawValue }

    var title: String {
        switch self {
        case .faces: "Faces"
        case .people: "People"
        case .food: "Food"
        case .animals: "Animals"
        case .objects: "Objects"
        case .activity: "Play"
        case .places: "Places"
        }
    }

    var emoji: [String] {
        switch self {
        case .faces:
            ["😊", "😀", "😃", "😁", "🙂", "😍", "🥰", "😘", "😎", "🤩",
             "😢", "😭", "😟", "😞", "😩", "😫", "😤", "😠", "😡", "🤬",
             "😴", "🥱", "😪", "🤒", "🤕", "🤧", "🤢", "😵", "🥵", "🥶",
             "😨", "😱", "😳", "😲", "🤔", "🤗", "🤭", "🙄", "😏", "🤫",
             "👍", "👎", "👋", "🙏", "👏", "🤝", "✋", "👌", "👀", "👂"]
        case .people:
            ["👶", "🧒", "👦", "👧", "🧑", "👨", "👩", "👴", "👵", "👨‍👩‍👧",
             "👨‍👩‍👦", "👩‍👧", "👨‍👧", "👪", "🫂", "❤️", "💛", "💚", "💙", "💜",
             "👨‍⚕️", "👩‍⚕️", "👨‍🏫", "👩‍🏫", "👨‍🍳", "👩‍🍳", "👮", "🧑‍🚒", "🧑‍🌾", "🧑‍🎨",
             "🤱", "🧎", "🚶", "🏃", "💃", "🕺", "🧘", "🛀", "🛌", "💤"]
        case .food:
            ["🍎", "🍌", "🍇", "🍓", "🍊", "🍋", "🍉", "🍑", "🥭", "🍍",
             "🥕", "🌽", "🥦", "🥒", "🍅", "🥑", "🍆", "🥔", "🧅", "🧄",
             "🍞", "🥐", "🥖", "🧀", "🥚", "🍳", "🥓", "🥞", "🧇", "🍗",
             "🍔", "🍟", "🌭", "🍕", "🌮", "🌯", "🥙", "🍣", "🍤", "🍜",
             "🍚", "🍝", "🍱", "🍙", "🍰", "🍪", "🍩", "🍫", "🍬", "🍭",
             "🥤", "🧃", "🥛", "☕️", "🧋", "🍵", "🥃", "🍼", "🧊", "🍯"]
        case .animals:
            ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯",
             "🦁", "🐮", "🐷", "🐸", "🐵", "🐔", "🐧", "🐦", "🐤", "🦆",
             "🦅", "🦉", "🦇", "🐺", "🐗", "🐴", "🦄", "🐝", "🐛", "🦋",
             "🐌", "🐞", "🐢", "🐍", "🦎", "🦖", "🐙", "🦑", "🦐", "🦀",
             "🐬", "🐳", "🐟", "🐠", "🦈", "🐊", "🐅", "🐆", "🦓", "🦒"]
        case .objects:
            ["📱", "💻", "⌨️", "🖥", "🖨", "📷", "📺", "📻", "🎙", "⏰",
             "💡", "🔦", "🕯", "🪞", "🛁", "🚽", "🪥", "🧴", "🧼", "🧻",
             "🧸", "🎈", "🎁", "📚", "📖", "✏️", "🖍", "🖌", "📝", "📔",
             "🔑", "🔒", "🛒", "💰", "💵", "💳", "🎒", "👜", "👓", "🕶",
             "👕", "👖", "👗", "🧦", "👟", "👞", "🧢", "🎩", "⛑", "🧤",
             "🦷", "👁", "👃", "👅", "👄", "🦴", "💉", "💊", "🩹", "🩺"]
        case .activity:
            ["⚽️", "🏀", "🏈", "⚾️", "🥎", "🎾", "🏐", "🏉", "🥏", "🎱",
             "🪀", "🏓", "🏸", "🥅", "🏒", "🏑", "🥍", "🏏", "🥊", "🥋",
             "🎮", "🎲", "🧩", "🎯", "🎨", "🖼", "🎭", "🎤", "🎧", "🎵",
             "🎶", "🎸", "🪕", "🎹", "🥁", "🎷", "🎺", "🎻", "📖", "🃏",
             "🚲", "🛴", "🛼", "🛷", "⛸", "🎿", "🏂", "🏊", "🤽", "🏄"]
        case .places:
            ["🏠", "🏡", "🏫", "🏥", "🏪", "🏬", "🏛", "⛪️", "🕌", "🛕",
             "🏞", "🌳", "🌲", "🌴", "🌵", "🌷", "🌹", "🌻", "🌼", "🌸",
             "🏖", "🏝", "🏜", "🏔", "⛰", "🌋", "🏕", "🛣", "🏟", "🎡",
             "🎢", "🎪", "🚗", "🚕", "🚙", "🚌", "🚎", "🚓", "🚑", "🚒",
             "🚜", "✈️", "🚀", "🚁", "🚂", "🚆", "🚇", "🚊", "🛴", "🛵"]
        }
    }
}
