# Plan: Grammar Support — Word Forms

**Status**: active  
**Priority**: TD Snap parity #6  
**Branch**: codex/ios-aac-mvp

## Goal
AAC users need word forms (eat → eating / ate / eats) to build grammatically correct
sentences. Parents set forms per word; the child long-presses any tile with forms and
picks the desired form, which gets added to the message bar exactly like tapping a tile.

## Design
- `AACWord.wordForms: [String]` — ordered list of alternate forms (e.g. ["eating","ate","eats"]).
  Codable, defaults to `[]`. Backward-compatible (missing key → empty).
- StarterVocabulary: ~25 high-frequency verbs/nouns seeded with common forms.
- **Kid mode**: long-press on a tile → new `WordFormsSheet` (bottom sheet) when
  `word.wordForms` is non-empty. Sheet shows large chips (same tile color) for each form.
  Tapping a chip adds a synthetic word to the message bar and dismisses.
- **Parent editor** (`EditWordView`): "Word forms" section — inline add/delete list.
- Context menu in kid mode still shows Speak / Favorite / Add to Quick Phrases as before;
  the forms sheet is triggered by the EXISTING long-press gesture on the `WordTileView`
  (add a new `.contextMenu` item "More forms…" that opens the sheet).

## Files
- `MyEchoAAC/Models/AACWord.swift` — add `wordForms: [String]`
- `MyEchoAAC/Services/StarterVocabulary.swift` — seed forms for ~25 words
- `MyEchoAAC/Views/WordFormsSheet.swift` — new
- `MyEchoAAC/Views/KidModeView.swift` — state + sheet trigger
- `MyEchoAAC/Views/EditWordView.swift` — forms section
- `MyEchoAACTests/WordFormsTests.swift` — new

## Tests (TDD — write first)
1. `AACWord` with `wordForms` round-trips through JSON
2. `AACWord` decoded without `wordForms` key defaults to `[]`
3. Seeded starter word "eat" has forms ["eating", "ate", "eats"]
4. Word with empty `wordForms` has no forms to show (isEmpty check)

## Done when
- [ ] Tests green
- [ ] Build succeeds
- [ ] Long-press a tile with forms → sheet shows forms
- [ ] Tapping a form adds it to the message bar
- [ ] EditWordView lets parents add/delete forms
- [ ] ROADMAP.md grammar support checked off
