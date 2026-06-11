# Plan: Keyboard Page (Type-to-Speak)

**Status**: todo  
**Priority**: TD Snap parity #2

## Goal
A dedicated "keyboard" page on the board that lets literate users type words with word prediction, then speak them. Accessible as a folder tile.

## Key decisions to make
- Integrate with `PredictionService` for prediction strip.
- Keyboard page shows as a special folder on the home fringe.
- Spoken text gets recorded in `UsageHistory`.

## Rough scope
- `KeyboardPageView` — full-grid keyboard layout or UIKit `UITextField` bridge.
- New `AACSettings` toggle: show/hide keyboard page.
- Integrate with existing message bar.
