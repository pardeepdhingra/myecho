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

Quality & testing
- [x] Fixed: pressed buttons could briefly show another word's symbol — the folder board's fixed grid identified cells by position, so SwiftUI reused a pressed cell's view for different content on reflow. Cells now carry content identity (word id / folder name).
- [x] Fixed: message-bar chips now show the same artwork as the tile (photo → picture symbol → emoji); they used to drop the picture symbol.
- [x] Word suggestions strip (`PredictionService`): on-device bigram learning from the child's own taps, seeded cold start, parent toggle.
- [x] UI tests run in landscape on iPads (primary AAC posture); verified on iPad (A16) simulator — closest available to iPad 9th gen.
- [x] Unit-test target (`MyEchoAACTests`, Swift Testing) — 49 tests covering board logic (`AACStore`), message building (`MessageComposer`), pronunciation, usage history, and backup payload coding. Run with `xcodebuild test -scheme MyEchoAAC`.
- [x] UI-test target (`MyEchoAACUITests`) — kid-mode journey: tap tiles → message bar → speak → delete → clear.
- [x] `AACStore` / `UsageHistory` accept an injected `UserDefaults` so tests are isolated from real child data.
- [x] Message building extracted from `KidModeView` into `MessageComposer`; fixed duplicate-word messages ("more more") having clashing SwiftUI identities.

## Next (can work on now)

- [ ] Polish first-run visual design and capture fresh simulator screenshots.
- [ ] Sign language: bulk/"suggest sign for this word" flow so parents don't search one at a time.
- [x] Sign language: handle/refresh download failures and offline gracefully — `SignDownloader` retries 3× with 1/2/3s backoff; `SignPickerView` shows "Try again" on search error and "Retry" button per result on download failure.
- [ ] Sign language: let parents trim/choose a thumbnail frame for each saved sign.
- [ ] Per-word sign learning card (tap to enlarge the sign + hear the word) for teaching moments.
- [x] Multiple boards via **Board sets** (Home, School, Therapy) — save/load/rename/overwrite named full-board snapshots (`BoardSetStore`, Parent → Board → Board sets). Self-contained files with embedded photos; the live board remains the single synced board.
- [ ] Per-profile cloud sync (each board set as its own cloud document) — needs a cross-platform contract revision in CLOUD_SYNC_PLAN.md first.
- [x] Basic UI tests for kid-mode message building (`MyEchoAACUITests/KidModeUITests`).

## TD Snap parity audit (2026-06-11)

Already at parity: Motor Plan folder board with fixed positions ✓, core-word band ✓, Fitzgerald word-type colours ✓, grid sizes 30/40/66/custom ✓, message window with symbol chips ✓, quick fires (quick phrases + regulation bar) ✓, progressive reveal (hide words/folders without moving buttons) ✓, page sets (board sets) ✓, backup/share ✓, cloud sync ✓, usage stats ✓, next-word prediction ✓ (TD Snap doesn't even have this on the symbol board).

Gaps to close, in value order:
- [x] **Word finder for the kid board** — search a word, show the path to it (folder + page) like TD Snap Search; therapists rely on this. Magnifying-glass button in kid-board header opens `WordFinderView`; tap result to add to message bar, "Locate" button navigates to the folder/category.
- [ ] **Keyboard page** — type-to-speak page with word prediction for literate users.
- [ ] **Bigger symbol library** — integrate an open symbol set (e.g. ARASAAC, license-permitting) with search + download; bundled set is small.
- [ ] **Switch scanning** — row/column scanning with external-switch and full-screen-tap support (TD Snap's core accessibility feature).
- [x] **Partner window** — flip the spoken message to face the communication partner. ↕ button in message bar opens full-screen rotated large-text overlay; tap anywhere dismisses.
- [ ] **Grammar support** — word forms/inflections (plurals, tenses) on long-press.
- [ ] **Visual scene displays** — photo scenes with tappable hotspots (early-communicator support).

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
