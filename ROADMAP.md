# Vani Roadmap

This is the working todo list for Vani. Keep items small enough to test with the child and mark them off only when they are genuinely usable.

## Ready now (shipped & on-device)

Core communication
- [x] Native SwiftUI AAC MVP.
- [x] Kid communication board with message bar and speech.
- [x] Parent mode for grid, words, visibility, and voice settings.
- [x] Offline iOS speech first.
- [x] ElevenLabs API key kept out of the iOS app.
- [x] Renamed app to वाणी (Vani).
- [x] First-run welcome screen.
- [x] Logo and app icon.

Board & content
- [x] Photo support for custom word tiles (library + camera).
- [x] Backup/export/import for the parent board (single `.vaniboard` JSON with embedded photos).
- [x] Usage history for parents (tile-tap counts today / this week).
- [x] Sentence history with one-tap repeat.
- [x] Parent PIN (Keychain).
- [x] iPad layout polish (up to 8 grid columns on iPad).
- [x] Favorites (star) and Favorites pseudo-category.
- [x] Recent pseudo-category powered by usage history.
- [x] Quick-phrase modes: speak immediately / add to message bar.
- [x] Long-press tile context menu (speak / favorite / add to phrases).
- [x] Word search + visibility filter in Parent → Words.
- [x] Dynamic Type + VoiceOver labels.
- [x] Haptic feedback + press animation.
- [x] Symbols-in-message-bar toggle.
- [x] Screen-stays-on (idle timer disabled) in kid mode.

Voice
- [x] User-provided ElevenLabs key stored in Keychain (parent settings).
- [x] Natural voice option toggle in parent settings.
- [x] Cache generated audio in Caches directory for frequently used words.
- [x] Fall back to offline iOS speech on error.
- [x] Pronunciation helper: phonetic overrides so tricky words/phrases speak more clearly (`PronunciationService`).

Sign language (per-word video, real sources)
- [x] Decision made: signs attach per-word and display on the tile (overlay), not a separate mode.
- [x] Per-word sign support — `signVideoPath` + `signLanguage` on each word, video stored locally (`SignVideoStore`).
- [x] Sign picker to search and download signs (`SignPickerView` / `SignSearchService`).
- [x] Source options by language: Auslan (Auslan Signbank) and ASL (signasl.org), with attribution shown.
- [x] Looping, muted sign playback on the tile (`SignVideoView` / `WordTileView`).
- [x] Uses real recorded videos — no AI-generated signs presented as authoritative.

Routine packs
- [x] Routine boards added for food, bathroom, play, school, bedtime, feelings, and pain/body (`RoutinePacks`).

## Next (can work on now)

- [ ] Polish first-run visual design and capture fresh simulator screenshots.
- [ ] Sign language: bulk/"suggest sign for this word" flow so parents don't search one at a time.
- [ ] Sign language: handle/refresh download failures and offline gracefully (retry + clearer errors).
- [ ] Sign language: let parents trim/choose a thumbnail frame for each saved sign.
- [ ] Per-word sign learning card (tap to enlarge the sign + hear the word) for teaching moments.
- [ ] Multiple boards / profiles (Home, School, Therapy).
- [ ] Basic UI tests for kid-mode message building.

## Voice (next)

- [ ] Build a small ElevenLabs voice proxy for distributable releases (key out of app).
- [ ] Expand pronunciation overrides and let parents add custom pronunciations per word.

## Later

- [ ] Word finder for parents.
- [ ] Progressive reveal without changing learned tile positions.
- [ ] Multiple child profiles.
- [ ] Cloud sync, only if privacy and reliability are clear.
- [ ] Therapist/share mode.

## Release / distribution notes

- [ ] Current on-device builds are Debug, signed with a personal Apple Development profile (expire ~7 days). Decide on TestFlight / Release signing for longer-lived installs.
