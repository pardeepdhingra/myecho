# Plan: Word Finder for the Kid Board

**Status**: active  
**Priority**: TD Snap parity — highest value gap  
**Branch**: codex/ios-aac-mvp

## Goal
Let therapists and parents quickly locate any word on the board by name. Tap the result to add it to the message bar; tap "Locate" to navigate to its folder (so the child can be shown where the word lives).

## Design
- Magnifying-glass button added to the kid-mode header (right of the info button).
- Tapping opens a `.sheet` — `WordFinderView`.
- Sheet has an auto-focused search field at the top.
- Results are cards showing: tile symbol + label + folder path (e.g. "📁 Food" or "⭐️ Core").
- Prefix matches ranked first, then alphabetical.
- **Tap card** → adds word to message bar, dismisses sheet.
- **"Locate" button** (arrow icon) → opens the word's folder (folder mode) or selects its category (flat mode), dismisses sheet.

## Files to create / modify
- `MyEchoAAC/Views/WordFinderView.swift` — new
- `MyEchoAAC/Models/AACStore.swift` — add `searchWords(matching:)`
- `MyEchoAAC/Views/KidModeView.swift` — search button + state + `navigateToWord(_:)`
- `MyEchoAACTests/WordFinderTests.swift` — new unit tests

## Tests (TDD — write first)
1. `searchWords` returns empty array for blank query
2. `searchWords` matches label prefix (case-insensitive)
3. `searchWords` matches mid-word in phrase
4. `searchWords` returns hidden words excluded
5. `searchWords` ranks prefix match above substring match
6. Path label for core word → "Core"
7. Path label for folder word → folder name

## Done when
- [ ] `WordFinderTests` all green
- [ ] Build succeeds
- [ ] Search sheet opens from kid board header
- [ ] Tapping a result adds to message bar
- [ ] Locate navigates to the correct folder
- [ ] ROADMAP.md "Word finder for the kid board" checked off
