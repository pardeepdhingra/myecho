# Testing

## Running the tests

```bash
cd MyEchoAAC
xcodebuild test \
  -project MyEchoAAC.xcodeproj \
  -scheme MyEchoAAC \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -derivedDataPath DerivedData
```

Or in Xcode: open the project and press **Cmd-U**.

## What exists

`MyEchoAACTests` is a unit-test bundle (Swift Testing, hosted in the app) covering the
pure logic that a non-verbal child and their parents depend on most:

| File | Covers |
|------|--------|
| `AACStoreTests.swift` | Board state: starter vocabulary, persistence, upsert/delete, visibility, favorites, folder styles, routine-pack merge/remove (idempotency), quick phrases, regulation buttons, tile-colour resolution |
| `MessageComposerTests.swift` | Message building: tap order, duplicate words, spoken-phrase use, punctuation polish, delete/clear |
| `PronunciationServiceTests.swift` | Phonetic overrides and normalization rules that make tricky words speak clearly |
| `UsageHistoryTests.swift` | Tap/sentence history, frequency counts, recency, caps, persistence |
| `BackupPayloadTests.swift` | `.vaniboard` payload round-trip and lenient decoding of older/cross-platform boards |

`MyEchoAACUITests` is a UI-test bundle covering the critical kid-mode journey:

| File | Covers |
|------|--------|
| `KidModeUITests.swift` | Tap tiles → chips collect in the message bar → Speak enables → Delete removes the last word → Clear empties; tapping the same word twice yields two chips |

## Design decisions

- **Injected `UserDefaults`** — `AACStore` and `UsageHistory` take `init(defaults:)`
  (production defaults to `.standard`). Every test creates a throwaway suite via
  `makeIsolatedDefaults()` so tests never read or write a real child's board.
- **No mocking frameworks** — the logic under test is value-type/state-machine style,
  so plain instances with isolated defaults are enough.
- **`MessageComposer` extraction** — message building used to live in `KidModeView`
  `@State`, untestable. It is now a model with per-tap entry identity, which also
  fixed duplicate-word messages ("more more") breaking SwiftUI `ForEach` identity.
- **`--uitest` launch argument** — the app starts from a known state (welcome sheet
  suppressed, starter board restored) so UI tests are deterministic.
- **Identifier-based UI queries** — tiles expose `tile_<label>`, message chips
  `chip_<label>`, controls `speakButton` / `deleteButton` / `clearButton`. Queries are
  type-agnostic (`descendants(matching: .any)`) because SwiftUI surfaces the message
  bar as a ScrollView and chips as collapsed "Other" elements.
- **UI tests only rely on early core words** ("want", "go") — later core words such as
  "more" can paginate onto a second fringe page on small screens.
