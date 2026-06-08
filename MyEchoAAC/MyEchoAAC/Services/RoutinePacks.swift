import Foundation

struct RoutinePack: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let words: [AACWord]
    let phrases: [QuickPhrase]
}

enum RoutinePacks {
    static let all: [RoutinePack] = [food, bathroom, play, school, bedtime, feelings, pain]

    static let food: RoutinePack =
        RoutinePack(
            id: "food",
            title: "Food & Meals",
            subtitle: "Eating, drinking, snacks, mealtime choices.",
            symbol: "🍽️",
            words: [
                AACWord(label: "eat", symbol: "🍽️", category: "Food", colorName: .green, position: 0),
                AACWord(label: "drink", symbol: "🥤", category: "Food", colorName: .teal, position: 0),
                AACWord(label: "more", symbol: "➕", category: "Food", colorName: .green, position: 0),
                AACWord(label: "all done", symbol: "✅", category: "Food", colorName: .orange, position: 0),
                AACWord(label: "water", symbol: "💧", category: "Food", colorName: .blue, position: 0),
                AACWord(label: "milk", symbol: "🥛", category: "Food", colorName: .gray, position: 0),
                AACWord(label: "juice", symbol: "🧃", category: "Food", colorName: .orange, position: 0),
                AACWord(label: "fruit", symbol: "🍎", category: "Food", colorName: .pink, position: 0),
                AACWord(label: "rice", symbol: "🍚", category: "Food", colorName: .yellow, position: 0),
                AACWord(label: "bread", symbol: "🍞", category: "Food", colorName: .yellow, position: 0),
                AACWord(label: "snack", symbol: "🍪", category: "Food", colorName: .orange, position: 0),
                AACWord(label: "hungry", symbol: "😋", category: "Food", colorName: .pink, position: 0)
            ],
            phrases: [
                QuickPhrase(text: "I am hungry", position: 0),
                QuickPhrase(text: "I want water", position: 0),
                QuickPhrase(text: "I am full", position: 0)
            ]
        )

    static let bathroom: RoutinePack =
        RoutinePack(
            id: "bathroom",
            title: "Bathroom",
            subtitle: "Toilet, washing, brushing teeth, bath time.",
            symbol: "🛁",
            words: [
                AACWord(label: "toilet", symbol: "🚽", category: "Bathroom", colorName: .blue, position: 0),
                AACWord(label: "wash hands", symbol: "🧼", category: "Bathroom", colorName: .teal, position: 0),
                AACWord(label: "brush teeth", symbol: "🪥", category: "Bathroom", colorName: .blue, position: 0),
                AACWord(label: "bath", symbol: "🛁", category: "Bathroom", colorName: .teal, position: 0),
                AACWord(label: "soap", symbol: "🧴", category: "Bathroom", colorName: .pink, position: 0),
                AACWord(label: "towel", symbol: "🩴", category: "Bathroom", colorName: .yellow, position: 0)
            ],
            phrases: [
                QuickPhrase(text: "I need toilet", position: 0),
                QuickPhrase(text: "I need bath", position: 0)
            ]
        )

    static let play: RoutinePack =
        RoutinePack(
            id: "play",
            title: "Play",
            subtitle: "Toys, music, outside, books.",
            symbol: "🧸",
            words: [
                AACWord(label: "play", symbol: "🧸", category: "Play", colorName: .yellow, position: 0),
                AACWord(label: "music", symbol: "🎵", category: "Play", colorName: .pink, position: 0),
                AACWord(label: "outside", symbol: "🌳", category: "Play", colorName: .green, position: 0),
                AACWord(label: "book", symbol: "📖", category: "Play", colorName: .orange, position: 0),
                AACWord(label: "ball", symbol: "⚽️", category: "Play", colorName: .blue, position: 0),
                AACWord(label: "draw", symbol: "🖍", category: "Play", colorName: .orange, position: 0),
                AACWord(label: "dance", symbol: "💃", category: "Play", colorName: .pink, position: 0),
                AACWord(label: "again", symbol: "🔁", category: "Play", colorName: .teal, position: 0)
            ],
            phrases: [
                QuickPhrase(text: "Let's play", position: 0),
                QuickPhrase(text: "Read a book", position: 0)
            ]
        )

    static let school: RoutinePack =
        RoutinePack(
            id: "school",
            title: "School",
            subtitle: "Classroom, teacher, work.",
            symbol: "🏫",
            words: [
                AACWord(label: "school", symbol: "🏫", category: "School", colorName: .orange, position: 0),
                AACWord(label: "teacher", symbol: "🧑‍🏫", category: "School", colorName: .blue, position: 0),
                AACWord(label: "friend", symbol: "🤝", category: "School", colorName: .yellow, position: 0),
                AACWord(label: "work", symbol: "✏️", category: "School", colorName: .gray, position: 0),
                AACWord(label: "ready", symbol: "👍", category: "School", colorName: .green, position: 0),
                AACWord(label: "break", symbol: "🧘", category: "School", colorName: .purple, position: 0)
            ],
            phrases: [
                QuickPhrase(text: "I need help", position: 0),
                QuickPhrase(text: "I am done", position: 0)
            ]
        )

    static let bedtime: RoutinePack =
        RoutinePack(
            id: "bedtime",
            title: "Bedtime",
            subtitle: "Sleep, pyjamas, story, kiss.",
            symbol: "🌙",
            words: [
                AACWord(label: "sleep", symbol: "😴", category: "Bedtime", colorName: .gray, position: 0),
                AACWord(label: "tired", symbol: "🥱", category: "Bedtime", colorName: .gray, position: 0),
                AACWord(label: "story", symbol: "📚", category: "Bedtime", colorName: .orange, position: 0),
                AACWord(label: "pajamas", symbol: "👕", category: "Bedtime", colorName: .blue, position: 0),
                AACWord(label: "kiss", symbol: "💋", category: "Bedtime", colorName: .pink, position: 0),
                AACWord(label: "lights off", symbol: "🌙", category: "Bedtime", colorName: .purple, position: 0)
            ],
            phrases: [
                QuickPhrase(text: "Good night", position: 0),
                QuickPhrase(text: "I am sleepy", position: 0)
            ]
        )

    static let feelings: RoutinePack =
        RoutinePack(
            id: "feelings",
            title: "Feelings & Body",
            subtitle: "Emotions, sensations, pain.",
            symbol: "💛",
            words: [
                AACWord(label: "happy", symbol: "😊", category: "Feelings", colorName: .yellow, position: 0),
                AACWord(label: "sad", symbol: "😢", category: "Feelings", colorName: .blue, position: 0),
                AACWord(label: "angry", symbol: "😠", category: "Feelings", colorName: .orange, position: 0),
                AACWord(label: "scared", symbol: "😟", category: "Feelings", colorName: .purple, position: 0),
                AACWord(label: "hurt", symbol: "🤕", category: "Feelings", colorName: .pink, position: 0),
                AACWord(label: "tired", symbol: "😴", category: "Feelings", colorName: .gray, position: 0),
                AACWord(label: "calm", symbol: "🧘", category: "Feelings", colorName: .teal, position: 0),
                AACWord(label: "love", symbol: "❤️", category: "Feelings", colorName: .pink, position: 0),
                AACWord(label: "head", symbol: "🤯", category: "Body", colorName: .gray, position: 0),
                AACWord(label: "tummy", symbol: "🤰", category: "Body", colorName: .pink, position: 0),
                AACWord(label: "leg", symbol: "🦵", category: "Body", colorName: .gray, position: 0),
                AACWord(label: "arm", symbol: "💪", category: "Body", colorName: .gray, position: 0)
            ],
            phrases: [
                QuickPhrase(text: "I am hurt", position: 0),
                QuickPhrase(text: "I love you", position: 0)
            ]
        )

    static let pain: RoutinePack =
        RoutinePack(
            id: "pain",
            title: "Pain & Body",
            subtitle: "Show where it hurts and how it feels.",
            symbol: "🩹",
            words: [
                AACWord(label: "hurt", symbol: "🤕", category: "Pain & Body", colorName: .pink, position: 0),
                AACWord(label: "a little", symbol: "🤏", category: "Pain & Body", colorName: .yellow, position: 0),
                AACWord(label: "a lot", symbol: "🔴", category: "Pain & Body", colorName: .orange, position: 0),
                AACWord(label: "head", symbol: "🧠", category: "Pain & Body", colorName: .gray, position: 0),
                AACWord(label: "tummy", symbol: "🤰", category: "Pain & Body", colorName: .pink, position: 0),
                AACWord(label: "ear", symbol: "👂", category: "Pain & Body", colorName: .gray, position: 0),
                AACWord(label: "tooth", symbol: "🦷", category: "Pain & Body", colorName: .blue, position: 0),
                AACWord(label: "throat", symbol: "😮", category: "Pain & Body", colorName: .teal, position: 0),
                AACWord(label: "leg", symbol: "🦵", category: "Pain & Body", colorName: .gray, position: 0),
                AACWord(label: "arm", symbol: "💪", category: "Pain & Body", colorName: .gray, position: 0),
                AACWord(label: "hot", symbol: "🥵", category: "Pain & Body", colorName: .orange, position: 0),
                AACWord(label: "itchy", symbol: "🐛", category: "Pain & Body", colorName: .green, position: 0),
                AACWord(label: "sick", symbol: "🤢", category: "Pain & Body", colorName: .green, position: 0),
                AACWord(label: "medicine", symbol: "💊", category: "Pain & Body", colorName: .purple, position: 0),
                AACWord(label: "doctor", symbol: "🩺", category: "Pain & Body", colorName: .blue, position: 0),
                AACWord(label: "help", symbol: "🆘", category: "Pain & Body", colorName: .orange, position: 0)
            ],
            phrases: [
                QuickPhrase(text: "It hurts here", position: 0),
                QuickPhrase(text: "I feel sick", position: 0),
                QuickPhrase(text: "I need medicine", position: 0)
            ]
        )
}
