# Vani (वाणी) — Android Handover: What Works & How It's Built

> **Purpose.** This is the master brief for an Android engineer rebuilding the Vani iOS AAC app at
> feature parity. It documents every shipped iOS feature, how it's implemented, the data model, the
> persistence layout, and the cross-platform cloud contract. It is a map — for three subsystems there
> are deeper existing docs you must read alongside it (linked below).
>
> **App.** Vani is a native AAC (Augmentative and Alternative Communication) app. Primary user: a child
> who communicates by tapping picture/word tiles to build and speak sentences. Secondary user: a
> parent/therapist who configures the board. Offline-first; cloud sync is optional.
>
> **iOS status:** v1.0, all features below shipped. Bundle id `com.pardeepdhingra.vani`, iOS 17.0 min,
> primary device iPad (landscape). Firebase project `vani-f34f6`.

## Companion docs (read these for the hard parts — do not re-derive)
- **`CLOUD_SYNC_PLAN.md`** — the authoritative cross-platform cloud contract. Part A = shared JSON
  shapes/field names/enums (the source of truth for the data model), Part B = sync engine semantics,
  Part D = iOS reference, Part E = Firebase setup. Android implements Part C against the same contract.
- **`MOTOR_PLAN_FOLDERS_ANDROID.md`** — the folder ("Motor Plan") board layout, the persistent core
  band, and the three colour modes, with a test checklist.
- **`FREEZE_BUTTON_POSITIONS_ANDROID.md`** — the freeze-button-positions algorithm for classic mode.
- `ROADMAP.md` — feature parity checklist vs. the TD Snap "Motor Plan" baseline.
- `CLAUDE.md` — architecture summary, conventions, build/test commands.

If anything here disagrees with `CLOUD_SYNC_PLAN.md` Part A, **Part A wins** for synced field shapes.

---

## 1. Architecture at a glance

iOS layering (mirror it on Android with Models / Repositories / ViewModels / Compose UI):

```
Models/    Plain value types (structs) — AACWord, AACSettings, QuickPhrase, AACScene, ChildProfile,
           SignLanguage, MessageComposer, and the central AACStore (in-memory board + persistence).
Services/  Business logic & I/O — TTS, prediction, pronunciation, usage stats, backups, board sets,
           cloud sync, sign/symbol search & download, file stores, scanning engine, profiles, PIN.
Views/     SwiftUI screens (→ Jetpack Compose on Android).
```

**Entry point** (`MyEchoAAC/MyEchoAAC/MyEchoAACApp.swift`): at launch it (1) calls
`CloudBootstrap.configure()` (Firebase init, a no-op if not configured), (2) resolves `DeviceID.current`
(stable per-install UUID), (3) constructs `ProfileStore` and reads the active profile's `UserDefaults`
suite, then builds `AACStore`, `UsageHistory`, `PredictionService`, `SpeechService`, `SceneStore`,
`AuthService`, `CloudSyncService` and injects them into the view tree. A `--uitest` launch arg resets to
a deterministic starter board.

**State pattern:** models are immutable structs; stores are observable objects whose `@Published`
properties persist on every mutation (`didSet` → save). Android equivalent: `StateFlow`/Room + a
repository that writes on change.

---

## 2. Persistence layout (and Android mapping)

All local; nothing leaves the device unless the user signs in.

| iOS mechanism | What it holds | Keys / paths | Android equivalent |
|---|---|---|---|
| `UserDefaults` (per profile) | words, settings, quick phrases, usage, sentences, predictions, deviceId, scenes | `vani.words.v1`, `vani.settings.v1`, `vani.phrases.v1`, `vani.usage.v1`, `vani.sentences.v1`, `vani.predictions.v1`, `vani.deviceId.v1`, `vani.scenes.v1` | Room (structured) or DataStore/Proto |
| Per-profile `UserDefaults` suite | isolated board per child | suite name `vani.profile.<uuid>` (default profile uses standard) | one Room DB (or schema) per profile id |
| Keychain | parent PIN only | service `com.pardeepdhingra.vani`, `.whenUnlockedThisDeviceOnly` | EncryptedSharedPreferences / Keystore |
| Documents/`word-images/` | custom word/scene photos (JPEG, ≤800px, q0.85) | `<uuid>.jpg` | app-internal files dir |
| Documents/`sign-videos/` | sign videos + derived thumbnails | `<uuid>.mp4`, `<uuid>.jpg` | app-internal files dir |
| Documents / temp | board export/import + board sets | `*.vaniboard` (JSON), `board-sets/index.json` + `board-sets/<uuid>.vaniboard` | files dir |

**Note on values that never sync:** `voiceIdentifier` (device-specific TTS voice) and the parent PIN are
device-local; `BoardCodec` strips `voiceIdentifier` before upload. Keep that behaviour on Android.

---

## 3. Data model (the synced shapes)

These are the canonical fields. **Use `CLOUD_SYNC_PLAN.md` Part A as the binding spec** (camelCase JSON,
UUID strings UPPERCASE, ISO-8601/RFC-3339 UTC timestamps, **lenient decoding** — unknown fields ignored,
missing fields defaulted). `schemaVersion` is `1`; refuse to apply a remote board with a higher version.

**AACWord** — one vocabulary tile.
`id (UUID)`, `label`, `phrase` (spoken text; defaults to label), `symbol` (emoji), `category` (folder
name; `"Core"` = persistent core band), `colorName` ∈ {blue, green, orange, pink, purple, teal, yellow,
gray, red, indigo, brown, mint, cyan, rose, coral}, `position (Int)`, `isVisible (Bool)`, `imagePath
(String?)` (photo file), `isFavorite (Bool)`, `favoritePosition (Int?)`, `sourcePackId (String?)`
(routine-pack provenance), `signVideoPath (String?)`, `signThumbnailPath (String?)`, `signLanguage` ∈
{auslan, asl} (nullable), `partOfSpeech` ∈ {noun, verb, adjective, pronoun, social, question,
joiningWord} (nullable; drives Fitzgerald-Key colour), `symbolName (String?)` (bundled picture-symbol
asset name, e.g. `sym_apple`), `colorOverride (TileColorName?)`, `wordForms ([String])` (grammar
variants).

**AACSettings** — board configuration. Key fields: `gridColumns`, `gridRows`, `gridPreset` ∈ {size30,
size40, size66, custom} (default size40), `coreColumns` (0–4, default 2), `boardMode` ∈ {folders,
classic} (default folders), `tileStyle` ∈ {outlined, filled} (default outlined), `colorMode` ∈
{byCategory, perWord, byWordType} (default byCategory; **new installs default byWordType**), `tileScale`
(0.7–1.8), `categoryOrder ([String])`, `hiddenCategories ([String])`, `categoryStyles` (per-category
colour+icon), `freezeButtonPositions`, `showCategoryFilter`, `showQuickPhrases`, `showRegulationBar`,
`showWordSuggestions`, `showKeyboardPage`, `showSymbolsInMessageBar`, `scanningEnabled`,
`scanIntervalSeconds`, `trackUsageHistory`, `showAllVoiceQualities`, `voiceIdentifier (String?, NOT
synced)`, `speechRate (Float)`, `pitchMultiplier (Float)`, `pronunciationOverrides ([String:String])`.
**Back-compat:** legacy `colorTilesByCategory: Bool` migrates to `colorMode` (true→byCategory,
false→perWord).

**QuickPhrase** — `id`, `text`, `position`, `mode` ∈ {speak, startSentence, regulation},
`sourcePackId (String?)`, `regulationKind` ∈ {calm, help, stop} (nullable; regulation buttons).

**AACScene** — `id`, `name`, `imagePath (String?)`, `position`, `isVisible`, `hotspots: [AACSceneHotspot]`
where a hotspot is `id, label, phrase, symbol, normalizedX, normalizedY, radius` (all 0–1 proportions, so
taps are device-resolution-independent).

**ChildProfile** — `id`, `name`, `emoji`, `isDefault`.

**UsageEntry** (synced for stats) — `id`, `wordId`, `label`, `timestamp (ISO-8601 UTC)`.

---

## 4. Feature inventory — what works and how

Each item: behaviour → iOS implementation (file) → Android notes. Features are gated by `AACSettings`
toggles unless noted.

### A. Core communication (kid board)
- **Tap-to-build-and-speak.** Child taps tiles → words become chips in the message bar → "Speak" reads
  the polished sentence (trim + terminal full stop) via on-device TTS; "Backspace" removes the last word;
  "Clear" empties. *(`KidModeView.swift`, `MessageComposer.swift`, `SpeechService.swift`.)* Each tapped
  word gets a fresh UUID so the same word can appear twice without list-identity bugs.
- **Two board modes.**
  - **Folders / "Motor Plan"** (default): a persistent left **core band** (`coreColumns` of always-
    visible `category == "Core"` words, identical on every page) + a paged fringe of folder tiles on the
    home page; opening a folder shows that category's words in fixed positions (hidden words leave blank
    placeholders to preserve muscle memory; trailing blanks trimmed). Fixed grid, swipe sideways to page.
  - **Classic / flat grid**: scrollable grid + category filter chips, with optional **freeze button
    positions** (keep each word in its absolute slot when filtering). *(`KidModeView.swift`; algorithms in
    `MOTOR_PLAN_FOLDERS_ANDROID.md` and `FREEZE_BUTTON_POSITIONS_ANDROID.md`.)*
- **Word tile.** Renders artwork + label, favorite-star badge, sign badge (tap → sign learning card),
  press animation, haptics; colored per colour-mode/override; outlined or filled style; square, scalable.
  *(`WordTileView.swift`.)*
- **Folder tile.** Bold solid-color category button with icon. *(`FolderTileView.swift`.)*
- **Unified artwork renderer (important for parity).** One renderer decides what a tile shows, in strict
  priority: **user photo → sign language (user thumbnail → auto thumbnail → looping video) → picture
  symbol (`symbolName`) → emoji (`symbol`)**. Use a single equivalent component on Android everywhere a
  word/folder icon appears, so the child sees identical artwork on every screen. Picture-symbol vs emoji
  rendering is shared with folder icons. *(`WordArtworkView.swift` + `SymbolOrEmojiView`.)*
- **Message bar.** Horizontal chips (optionally showing artwork), placeholder when empty, recent-sentence
  replay. *(`KidModeView.swift`, `SentenceHistorySheet.swift`.)*
- **Next-word suggestions.** A prediction strip offers the most likely next words. *(below.)*
- **Quick phrases & regulation bar.** One-tap phrases that either speak immediately, seed the message
  bar, or act as pinned emotional-regulation buttons (Calm/Help/Stop). *(`KidModeView.swift`,
  `QuickPhrase.swift`.)*
- **Partner window.** Full-screen, 180°-rotated message display so a partner across the table can read
  it; tap to dismiss. *(`PartnerWindowView.swift`.)*

### B. On-device intelligence
- **Next-word prediction.** A bigram model: `transitions[context][nextLabel] = count`, where context is
  the lowercased previous word or `"^start"`. Learns from the child's own taps; seeded with ~12 common
  pairs at count 1; per-context bucket capped at 50 (drop rarest). `suggestions(after:candidates:limit:)`
  ranks by context count, then global frequency. *(`PredictionService.swift`; persisted at
  `vani.predictions.v1`.)*
- **Pronunciation engine.** 3-tier: parent `pronunciationOverrides` → built-in phrase/word dictionary →
  simple phonetic rules (ice→ise, igh→eye, ph→f, ck→k, qu→kw, c→k). Returns nil when unchanged so the UI
  doesn't show redundant suggestions. Parents manage custom overrides in a library screen.
  *(`PronunciationService.swift`, `PronunciationLibraryView.swift`.)*
- **Usage history & stats.** Records taps (`wordId,label,timestamp`, capped 2000) and spoken sentences
  (MRU, capped 25). Powers today/this-week top-10 word counts, a "Recent" pseudo-category, and a
  plain-text **session report** shareable with a therapist. *(`UsageHistory.swift`; keys `vani.usage.v1`,
  `vani.sentences.v1`.)*

### C. Symbols, photos & sign language
- **Picture symbols.** Bundled ARASAAC pictograms named `sym_*` in the asset catalog (ship the identical
  set on Android so `symbolName` restores render). Lookup/search via `SymbolLibrary.swift`.
- **ARASAAC online library.** Search + download pictograms from `api.arasaac.org` /
  `static.arasaac.org/.../{id}_300.png`, saved through `ImageStore`. *(`AARASAACService.swift`,
  `SymbolPickerView.swift`.)*
- **Custom photos.** Camera or photo library → resized to ≤800px JPEG → stored as `imagePath`.
  *(`CameraPicker.swift`, `ImageStore.swift`, `EditWordView.swift`.)*
- **Sign language (Auslan + ASL).** Search Auslan Signbank (auslan.org.au) and signasl.org, download the
  MP4 (3 retries), auto-generate a thumbnail from a frame ~0.2s before the end (`AVAssetImageGenerator`).
  A **sign learning card** plays the looping video full-screen + speaks the word. A **thumbnail picker**
  lets parents choose the still frame. A **bulk-sign** screen assigns signs to many unsigned words at
  once. *(`SignSearchService.swift`, `SignVideoStore.swift`, `SignPickerView.swift`,
  `SignThumbnailPickerView.swift`, `SignLearningCardView.swift`, `BulkSignView.swift`; Android: ExoPlayer
  + MediaMetadataRetriever.)*
- **Error surfacing (recent fix).** `ImageStore.save` throws a typed error and the photo/symbol/sign UIs
  show an alert on failure instead of silently falling back to a blank tile. Replicate visible-error
  behaviour on Android.

### D. Word editor (`EditWordView.swift`) — everything configurable per word
Label; spoken phrase (with pronunciation suggestion + hear button); emoji picker; bundled + online
picture symbol; custom photo (camera/library); sign video + sign thumbnail frame; **word forms/grammar**
variants (long-press a tile to pick an inflection — `WordFormsSheet.swift`); category (or create one
inline); pin-to-home (move to/from Core band); word type (Fitzgerald Key); per-button color override;
visible toggle; favorite toggle; a live "what the child sees" tile preview.

### E. Parent / therapist configuration (`ParentModeView.swift`, tabbed)
- **Board tab:** grid preset/columns/rows, core-band width, board mode, tile style, tile scale, color
  mode, category reorder/hide + per-category color/icon, display toggles (quick phrases, regulation bar,
  suggestions, keyboard page, symbols-in-message-bar, switch scanning + speed), add starter vocabulary,
  add **routine packs** (14 curated sets — food, bathroom, play, school, bedtime, feelings, pain,
  animals, colors, numbers, weather, vehicles, family, outdoors; idempotent, dedup by label, tagged with
  `sourcePackId`), order favorites, **board sets**, and **export/import** `.vaniboard`.
- **Words tab:** searchable/filterable word list with reorder, visibility toggle, delete, and entry to
  bulk-sign / quick-reveal / word-finder.
- **Quick Reveal:** show *all* words (incl. hidden) and toggle visibility without leaving holes — a
  planning aid. *(`QuickRevealView.swift`.)*
- **Word Finder (parent + kid):** search any word and see/jump to its folder location. *(`WordFinderView.swift`,
  `ParentWordFinderView.swift`.)*
- **Voice tab:** pick TTS voice (premium/enhanced; option to show robotic/compact), speed, pitch, preview.
- **Stats tab:** usage counts, recent sentences, session-report share.
- **Account tab:** cloud sign-in/out, Sync now, Restore from cloud. *(`AccountView.swift`, `AuthSheet.swift`.)*
- **PIN gate:** optional 4-digit parent lock (Keychain). *(`PINGateView.swift`, `PINStore.swift`.)*

### F. Backups & multiple boards
- **`.vaniboard` export/import** — a single self-contained JSON file: version, exportedAt, words, quick
  phrases, settings, and **all referenced photos embedded as base64 JPEG**, so it's portable. Apply is
  atomic and does not delete scene images. *(`BoardBackup.swift`.)*
- **Board sets** — named snapshots (Home / School / Therapy), each a self-contained `.vaniboard`; loading
  one replaces the live board (destructive — save first). *(`BoardSetStore.swift`, `BoardSetsView.swift`.)*

### G. Visual Scene Displays
A photo with circular tappable **hotspots**; tapping a hotspot speaks its word and adds it to the message
bar. Parents create scenes, place hotspots (normalized coords), and scenes appear as tiles in the folder
fringe. *(`AACScene.swift`, `SceneStore.swift`, `SceneEditorView.swift`, `SceneView.swift`,
`SceneListView.swift`, `SceneTileView.swift`; key `vani.scenes.v1`.)*

### H. Accessibility & input
- **Switch scanning.** Row→cell state machine with manual or auto (timer) advance and a highlight
  overlay; works in both board modes. *(`ScanningEngine.swift`, `KidModeView.swift`; gated by
  `scanningEnabled`/`scanIntervalSeconds`.)*
- **Keyboard page.** Type-to-speak for literate kids with vocabulary type-ahead. *(`KeyboardPageView.swift`.)*
- **Haptics** on taps/actions/success. *(`Haptics.swift`.)*
- Accessibility labels/identifiers throughout (also used by UI tests).

### I. Multi-child, onboarding, account
- **Profiles.** Multiple children, each with an isolated board/settings/stats via a separate prefs suite;
  switch from the parent header. *(`ProfileStore.swift`, `ProfileSwitcherView.swift`, `ChildProfile.swift`.)*
- **Onboarding.** 4-page first-run carousel. *(`WelcomeView.swift`.)*
- **About.** Story + attributions. *(`AboutView.swift`.)*

---

## 5. Cloud sync (summary — full spec in `CLOUD_SYNC_PLAN.md`)
- **Backend:** Firebase Auth (email/password + Apple on iOS; Android may add email link), Firestore
  (board doc), Storage (assets). Offline-first; if Firebase isn't configured the app runs fully offline
  (`status = .disabled`).
- **Firestore:** `/users/{uid}/board/current` holds five JSON-string fields (words, quickPhrases,
  settings, usageEntries, spokenSentences) + `updatedAtClient`, `deviceId`, `schemaVersion`,
  `hasPendingWrites`. `/users/{uid}/assets/{filename}` holds per-file metadata for reconciliation/GC.
- **Storage:** `users/{uid}/word-images/{file}`, `users/{uid}/sign-videos/{file}`, and `…/{file}.jpg`
  thumbnails.
- **Semantics:** debounced 3s push; **last-write-wins** by `(updatedAtClient, deviceId)`; SHA-256
  **content hash** to skip no-op uploads and suppress self-echo; per-uid high-water mark; first-sign-in
  reconcile prompt when both local and remote have real data.
- **Asset handling (carry these fixes over):** never treat a failed asset-index read as "empty" (that
  would skip downloading the child's media); propagate the error and abort the pass. Surface listener
  errors. Don't report "synced" when an asset leg failed.

---

## 6. External services & attribution (must carry over)
- **ARASAAC pictograms** — Sergio Palao / ARASAAC, CC BY-NC-SA. Bundled `sym_*` set + online API.
- **Mulberry symbols** — CC BY-SA 4.0 (where used).
- **Auslan** — Auslan Signbank (auslan.org.au), CC BY-NC-ND 4.0.
- **ASL** — signasl.org.
- **Firebase** — Auth / Firestore / Storage, project `vani-f34f6` (Android needs its own
  `google-services.json` registered to the same project + the matching package name).
- **TTS** — on-device only (iOS `AVSpeechSynthesizer`; **no** network TTS). Android: `android.speech.tts.TextToSpeech`.

---

## 7. Android parity checklist
- [ ] Data models + lenient JSON codec matching `CLOUD_SYNC_PLAN.md` Part A (UUID upper, RFC-3339 UTC,
      schemaVersion 1, `colorTilesByCategory`→`colorMode` migration, strip `voiceIdentifier`).
- [ ] Local persistence (Room/DataStore) with per-profile isolation; file stores for images & sign videos.
- [ ] Single unified artwork renderer (photo → sign → picture symbol → emoji) used everywhere.
- [ ] Folder ("Motor Plan") board + persistent core band + paging (`MOTOR_PLAN_FOLDERS_ANDROID.md`).
- [ ] Classic board + freeze-button-positions (`FREEZE_BUTTON_POSITIONS_ANDROID.md`).
- [ ] Three colour modes incl. Fitzgerald-Key `byWordType`; deterministic per-category default colours.
- [ ] Message bar / speak / clear / partner window; on-device TTS with rate/pitch/voice.
- [ ] Bigram prediction; pronunciation 3-tier engine + library; usage stats + session report.
- [ ] Picture symbols (bundled identical `sym_*` set + ARASAAC online); custom photos with visible errors.
- [ ] Sign language search/download (Auslan + ASL), thumbnails, learning card, bulk sign.
- [ ] Full word editor incl. word forms/grammar; routine packs; quick reveal; word finders.
- [ ] Quick phrases + regulation bar; visual scene displays; switch scanning; keyboard page; haptics.
- [ ] `.vaniboard` export/import (embedded base64 photos) + board sets.
- [ ] Multiple profiles; onboarding; PIN gate; about/attribution.
- [ ] Firebase cloud sync per `CLOUD_SYNC_PLAN.md` Part C, validated cross-platform against iOS.

---

## 8. Build & test (iOS reference)
- Build: `xcodebuild build -scheme MyEchoAAC -destination 'platform=iOS Simulator,name=iPad (A16)'`
- Test (Swift Testing + XCUITest): `xcodebuild test -scheme MyEchoAAC -destination 'platform=iOS Simulator,name=iPad (A16)'`
- UI tests launch with `--uitest` for a deterministic starter board.
- Tests inject isolated `UserDefaults` (`makeIsolatedDefaults()`); never touch real child data. Target 80%+.
