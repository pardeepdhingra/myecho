# Vani Roadmap

This is the working todo list for Vani. Keep items small enough to test with the child and mark them off only when they are genuinely usable.

## Now

- [x] Build native SwiftUI AAC MVP.
- [x] Add kid communication board with message bar and speech.
- [x] Add parent mode for grid, words, visibility, and voice settings.
- [x] Use offline iOS speech first.
- [x] Keep ElevenLabs API key out of the iOS app.
- [x] Rename app to वाणी (Vani).
- [x] First-run welcome screen.
- [ ] Polish first-run visual design and simulator screenshots.
- [ ] Add logo and app icon.

## Next

- [x] Add photo support for custom word tiles (library + camera).
- [x] Add backup/export/import for the parent board (single `.vaniboard` JSON with embedded photos).
- [x] Add simple usage history for parents (tile-tap counts today / this week).
- [x] Add sentence history with one-tap repeat.
- [x] Add parent PIN (Keychain).
- [x] Add iPad layout polish (up to 8 grid columns on iPad).
- [x] Add favorites (star) and Favorites pseudo-category.
- [x] Add Recent pseudo-category powered by usage history.
- [x] Add quick-phrase modes: speak immediately / add to message bar.
- [x] Add long-press tile context menu (speak / favorite / add to phrases).
- [x] Add word search + visibility filter in Parent → Words.
- [x] Add Dynamic Type + VoiceOver labels.
- [x] Add haptic feedback + press animation.
- [x] Add symbols-in-message-bar toggle.
- [x] Add screen-stays-on (idle timer disabled) in kid mode.
- [ ] Add routine boards for food, bathroom, play, school, bedtime, feelings, and pain/body.
- [ ] Add multiple boards / profiles (Home, School, Therapy).
- [ ] Add basic UI tests for kid-mode message building.

## Voice

- [x] User-provided ElevenLabs key stored in Keychain (parent settings).
- [x] Add natural voice option toggle in parent settings.
- [x] Cache generated audio in Caches directory for frequently used words.
- [x] Fall back to offline iOS speech on error.
- [ ] Build a small ElevenLabs voice proxy for distributable releases (key out of app).

## Sign Language Mode

- [ ] Research how AAC apps represent signs: static symbols, photos, short clips, animated hands, or caregiver-recorded videos.
- [ ] Decide whether sign language should be a separate mode, a tile overlay, or a per-word learning card.
- [ ] Explore sign-source options by region/language, including Auslan relevance if needed.
- [ ] Prototype per-word sign support with image/video attached to each word.
- [ ] Explore generated sign illustrations only after checking accuracy and safety with a qualified source.
- [ ] Avoid presenting generated signs as authoritative unless reviewed.

## Later

- [ ] Word finder for parents.
- [ ] Progressive reveal without changing learned tile positions.
- [ ] Multiple child profiles.
- [ ] Cloud sync, only if privacy and reliability are clear.
- [ ] Therapist/share mode.
