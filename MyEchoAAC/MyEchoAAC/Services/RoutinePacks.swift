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
    static let all: [RoutinePack] = [
        food, bathroom, play, school, bedtime, feelings, pain,
        animals, colors, numbers, weather, vehicles, family, outdoors
    ]

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

    // MARK: - Additional packs (parents can add these directly)

    private static func noun(_ label: String, _ emoji: String, _ cat: String) -> AACWord {
        AACWord(label: label, symbol: emoji, category: cat, colorName: .orange, position: 0, partOfSpeech: .noun)
    }
    private static func adj(_ label: String, _ emoji: String, _ cat: String) -> AACWord {
        AACWord(label: label, symbol: emoji, category: cat, colorName: .blue, position: 0, partOfSpeech: .adjective)
    }

    static let animals = RoutinePack(
        id: "animals", title: "Animals", subtitle: "Pets, farm and wild animals.", symbol: "🐶",
        words: [noun("dog","🐶","Animals"), noun("cat","🐱","Animals"), noun("bird","🐦","Animals"),
                noun("fish","🐟","Animals"), noun("cow","🐮","Animals"), noun("horse","🐴","Animals"),
                noun("pig","🐷","Animals"), noun("sheep","🐑","Animals"), noun("duck","🦆","Animals"),
                noun("rabbit","🐰","Animals"), noun("lion","🦁","Animals"), noun("elephant","🐘","Animals"),
                noun("monkey","🐵","Animals"), noun("bear","🐻","Animals")],
        phrases: [QuickPhrase(text: "I like animals", position: 0)])

    static let colors = RoutinePack(
        id: "colors", title: "Colors", subtitle: "Name and choose colors.", symbol: "🎨",
        words: [adj("red","🔴","Colors"), adj("blue","🔵","Colors"), adj("green","🟢","Colors"),
                adj("yellow","🟡","Colors"), adj("orange","🟠","Colors"), adj("purple","🟣","Colors"),
                adj("pink","🌸","Colors"), adj("black","⚫","Colors"), adj("white","⚪","Colors"),
                adj("brown","🟤","Colors")],
        phrases: [QuickPhrase(text: "I want the blue one", position: 0)])

    static let numbers = RoutinePack(
        id: "numbers", title: "Numbers", subtitle: "Count from one to ten.", symbol: "🔢",
        words: [adj("one","1️⃣","Numbers"), adj("two","2️⃣","Numbers"), adj("three","3️⃣","Numbers"),
                adj("four","4️⃣","Numbers"), adj("five","5️⃣","Numbers"), adj("six","6️⃣","Numbers"),
                adj("seven","7️⃣","Numbers"), adj("eight","8️⃣","Numbers"), adj("nine","9️⃣","Numbers"),
                adj("ten","🔟","Numbers")],
        phrases: [QuickPhrase(text: "I want two", position: 0)])

    static let weather = RoutinePack(
        id: "weather", title: "Weather", subtitle: "Sunny, rainy, hot and cold.", symbol: "🌤️",
        words: [adj("sunny","☀️","Weather"), adj("rainy","🌧️","Weather"), adj("cloudy","☁️","Weather"),
                adj("windy","🌬️","Weather"), adj("hot","🥵","Weather"), adj("cold","🥶","Weather"),
                noun("snow","❄️","Weather"), noun("storm","⛈️","Weather"), noun("rainbow","🌈","Weather")],
        phrases: [QuickPhrase(text: "It is raining", position: 0)])

    static let vehicles = RoutinePack(
        id: "vehicles", title: "Vehicles", subtitle: "Things that go.", symbol: "🚗",
        words: [noun("car","🚗","Vehicles"), noun("bus","🚌","Vehicles"), noun("train","🚆","Vehicles"),
                noun("plane","✈️","Vehicles"), noun("bike","🚲","Vehicles"), noun("boat","⛵","Vehicles"),
                noun("truck","🚚","Vehicles"), noun("helicopter","🚁","Vehicles"), noun("fire truck","🚒","Vehicles")],
        phrases: [QuickPhrase(text: "I want to go in the car", position: 0)])

    static let family = RoutinePack(
        id: "family", title: "Family", subtitle: "People in the family.", symbol: "👪",
        words: [noun("mum","👩","Family"), noun("dad","👨","Family"), noun("sister","👧","Family"),
                noun("brother","👦","Family"), noun("grandma","👵","Family"), noun("grandpa","👴","Family"),
                noun("baby","👶","Family"), noun("aunty","👩‍🦰","Family"), noun("uncle","🧔","Family"),
                noun("cousin","🧒","Family")],
        phrases: [QuickPhrase(text: "I want my mum", position: 0)])

    static let outdoors = RoutinePack(
        id: "outdoors", title: "Outdoors & Play", subtitle: "Park, playground and nature.", symbol: "🏞️",
        words: [noun("park","🏞️","Outdoors"), noun("playground","🛝","Outdoors"), noun("slide","🛝","Outdoors"),
                noun("swing","🎠","Outdoors"), noun("tree","🌳","Outdoors"), noun("grass","🌿","Outdoors"),
                noun("flower","🌷","Outdoors"), noun("sand","🏖️","Outdoors"), noun("beach","🏖️","Outdoors"),
                noun("garden","🌻","Outdoors")],
        phrases: [QuickPhrase(text: "I want to go outside", position: 0)])
}
