# Plan: Partner Window

**Status**: active  
**Priority**: TD Snap parity #5 (but quick to ship)  
**Branch**: codex/ios-aac-mvp

## Goal
After the child composes a message, the parent/therapist taps a "flip" button and the
screen shows the message in large text rotated 180° so the communication partner
sitting across the table can read it without turning the iPad.

## Design
- "Flip" button (↕ icon) added to the message-bar action row, right of Speak.
- Only enabled when the message bar is non-empty.
- Opens a `fullScreenCover` (`PartnerWindowView`) — full black screen, large white text,
  rotated 180°. A dim "Tap to close" hint at the bottom edge (from the partner's view).
- Tap anywhere to dismiss.
- Works for both board modes.

## Files
- `MyEchoAAC/Views/PartnerWindowView.swift` — new
- `MyEchoAAC/Views/KidModeView.swift` — flip button + fullScreenCover state
- `MyEchoAACTests/PartnerWindowTests.swift` — new (view model logic only)

## Tests (TDD)
1. Empty message → button disabled (logic test via `MessageComposer.isEmpty`)
2. Non-empty message → `polishedSentence` is what partner window shows (composer)
3. Dynamic font size: long message should fit (visual only, skip in unit tests)

## Done when
- [ ] Build succeeds
- [ ] Button appears in message bar, disabled when bar is empty
- [ ] Partner window opens full-screen with message rotated
- [ ] Tap anywhere dismisses
- [ ] ROADMAP.md partner window checked off
