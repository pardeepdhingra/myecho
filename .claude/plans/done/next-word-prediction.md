# Plan: Next-Word Suggestion Strip

**Status**: done  
**Merged**: 2026-06-11 (commit 86a2f82)

## What was built
- `PredictionService` — on-device bigram learning from child's taps, stored in `UserDefaults`.
- Cold-start seeding with common core-word pairs.
- Suggestion strip above the message bar in `KidModeView` (light-bulb icon + word chips).
- Parent toggle in Parent → Grid: "Show word suggestions".
- `AACSettings.showWordSuggestions` persisted.
- 11 unit tests in `PredictionServiceTests`.

## Files changed
- `Services/PredictionService.swift` (new)
- `Models/AACSettings.swift` (new toggle)
- `Views/KidModeView.swift` (suggestion strip + `addWord` records transition)
- `Views/ParentModeView.swift` (toggle)
- `MyEchoAACApp.swift` (inject `PredictionService`)
- `MyEchoAACTests/PredictionServiceTests.swift` (new)
