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
| `PronunciationServiceTests.swift` | Phonetic overrides and normalization rules that make tricky words speak clearly |
| `UsageHistoryTests.swift` | Tap/sentence history, frequency counts, recency, caps, persistence |
| `BackupPayloadTests.swift` | `.vaniboard` payload round-trip and lenient decoding of older/cross-platform boards |

## Design decisions

- **Injected `UserDefaults`** — `AACStore` and `UsageHistory` take `init(defaults:)`
  (production defaults to `.standard`). Every test creates a throwaway suite via
  `makeIsolatedDefaults()` so tests never read or write a real child's board.
- **No mocking frameworks** — the logic under test is value-type/state-machine style,
  so plain instances with isolated defaults are enough.
- **UI tests are still to do** — kid-mode message building (tap tiles → message bar →
  speak) should get an XCUITest journey before release builds.
