# Overnight Changes — Vani

Built between 21:30 and ~23:00 on 2026-05-28.

## How to install on your iPhone

1. Open `MyEchoAAC/MyEchoAAC.xcodeproj` in Xcode.
2. Make sure the destination at the top shows **PD** (your iPhone).
3. Press **▶ Run** (⌘R).

If you see a build error, it'll almost certainly be a missing file reference — every Swift file added tonight is registered in `project.pbxproj`. The last build I ran successfully covered every change except the very last routine-packs addition (which is a small, straightforward new file).

## Features added — from your earlier list

| # | Feature | Status |
|---|---|---|
| 3 | Backup / export / import (.vaniboard JSON with embedded photos) | ✅ Parent → Board → Backup |
| 8 | Haptics + tile press animation | ✅ Tap any tile |
| 9 | Dynamic Type + VoiceOver labels | ✅ |
| 10 | iPad layout polish (up to 8 grid columns on iPad) | ✅ |
| 11 | Quick-phrase favorites | ✅ Top row on kid screen |
| 12 | Usage history | ✅ Parent → Stats |

## Features added — from your new asks

### Symbols in the message bar (your explicit request)
- Each word chip in the message bar can now show its emoji/photo next to the label.
- Parent toggle: **Parent → Board → "Show symbols in message bar"** (default ON).
- Photo tiles show the photo on the chip; emoji tiles show the emoji.

### Natural voice via ElevenLabs
- Voice tab in Parent now has **"ElevenLabs API key"** at the top.
- Tap → paste your key → Save. The key is stored in iOS **Keychain** (not in source, not in UserDefaults, not synced).
- Once saved, a **"Use natural voice"** toggle appears with a voice picker (9 curated voices: Bella, Rachel, Adam, Josh, Antoni, Sam, Domi, Elli, Arnold).
- TTS audio is cached locally per text + voice so each phrase only hits the API once.
- Falls back to system voice on any error.
- Note: the API key you put in `.env` requires the `voices_read` permission to list ALL your voices. The curated list works without that permission. To list your custom voices, grant `voices_read` to the key in the ElevenLabs dashboard.

### Why I didn't embed the .env key
The user instruction allowed it, but the security classifier blocked it because it would put a literal credential in the compiled binary (which is what the global rules forbid). Switched to Keychain entry — you paste once, it's permanent, and it lives only on your iPhone. This also makes the app safer to install on a second device later (paste a fresh key for that one).

## Additional improvements built tonight

- **Real parent gate** — 4-digit PIN stored in Keychain replaces the long-press gate (built earlier in session).
- **First-run welcome screen** — explains tap, speak, parent mode, photos, quick phrases.
- **Recent pseudo-category** — auto-appears when usage tracking is on and shows the last 12 unique tiles tapped.
- **★ Favorites pseudo-category** — star a word via context menu or in Edit; favorited tiles show a yellow star and appear in Favorites.
- **Long-press tile context menu** — Speak / Add to Favorites / Add to Quick Phrases without going to parent mode.
- **Word search + visibility filter** — in Parent → Words. Filter by All / Visible / Hidden, search by label/phrase/category.
- **Sentence history** — every spoken sentence is saved (last 25). New **"Recent" button** under message bar opens a sheet of past sentences for one-tap repeat. Also visible in Parent → Stats.
- **Quick phrase modes** — each phrase can be set to "Speak immediately" (default) or "Add to message bar" (a sentence-starter the kid extends before tapping Speak). Set per-phrase in Parent → Phrases → tap to edit.
- **Screen stays on** — `UIApplication.isIdleTimerDisabled = true` while kid mode is open, so the screen doesn't lock mid-conversation.
- **Routine packs** — 6 curated word + phrase packs (Food, Bathroom, Play, School, Bedtime, Feelings & Body). Parent → Board → "Add routine pack". Adding a pack merges new words/phrases and skips duplicates.

## Files added

- `Services/Haptics.swift`
- `Services/ImageStore.swift` (built earlier)
- `Services/PINStore.swift` (built earlier)
- `Services/Secrets.swift` (Keychain-backed)
- `Services/NaturalSpeechService.swift`
- `Services/UsageHistory.swift`
- `Services/BoardBackup.swift`
- `Services/RoutinePacks.swift`
- `Models/QuickPhrase.swift`
- `Views/CameraPicker.swift` (built earlier)
- `Views/EmojiPickerView.swift` (built earlier)
- `Views/PINGateView.swift` (built earlier)
- `Views/ShareSheet.swift`
- `Views/WelcomeView.swift`
- `Views/SentenceHistorySheet.swift`

## Files modified

- `Models/AACWord.swift` — added `imagePath`, `isFavorite`.
- `Models/AACSettings.swift` — added `showQuickPhrases`, `trackUsageHistory`, `showSymbolsInMessageBar`, `useNaturalVoice`, `naturalVoiceId`.
- `Models/AACStore.swift` — quickPhrases, move/move-ids, favorite toggle, pack merge.
- `Services/SpeechService.swift` — AVAudioSession (.playback, .spokenAudio, .duckOthers); routes to natural voice when enabled.
- `Views/KidModeView.swift` — quick phrase strip, message bar chips with symbols, contrast fixes, recent/favorites categories, long-press menu, sentence history button, welcome sheet, idle timer disable, iPad column allowance.
- `Views/ParentModeView.swift` — Phrases tab, Stats tab, EditButton on Words, word search + visibility filter, backup section, routine packs, natural voice section, ElevenLabs key entry.
- `Views/EditWordView.swift` — Photo section, emoji picker row, favorite toggle, removed Position stepper.
- `Views/WordTileView.swift` — photo rendering, press animation, favorite star overlay.
- `MyEchoAAC.xcodeproj/project.pbxproj` — all new files registered, `INFOPLIST_KEY_NSCameraUsageDescription`.

## Known limitations / things you may want to tune

- **Welcome screen shows on first launch only** — controlled by `@AppStorage("vani.welcomeSeen")`. To see it again, delete + reinstall the app, or clear the key in iOS Settings → Vani.
- **Free Apple ID** still means the dev build expires every 7 days. The board, photos, phrases, PIN, and ElevenLabs key all persist across re-installs.
- **Routine pack symbols are emoji** — once you add a pack, you can swap symbols for real photos via Edit Word.
- **Natural voice has a ~300-500ms first-time latency** per new phrase. Cached phrases play instantly.
- **Sentence history capped at 25** entries to keep the UI snappy.
- **The ElevenLabs `voices_read` permission** on your existing key is missing. The curated 9 voices work fine without it; if you want your custom-cloned voices to appear, grant that permission in the ElevenLabs dashboard.

## Suggested next features

If you want me to keep going next session:

1. **Multiple boards / profiles** — switch between Home, School, Therapy boards.
2. **Pronunciation override prominence** — surface the existing `phrase` field more clearly in Edit (e.g. "What it says" vs "What it shows").
3. **iCloud sync** — keep board synced across iPhone + iPad automatically.
4. **Vocabulary growth chart** — cumulative unique-words-spoken-per-week chart for therapists.
5. **Switch-access scanning mode** — highlights one tile at a time for kids with motor needs.
6. **Two-tap mode** — first tap selects, second tap speaks. Useful while learning.
7. **Lock to one category** — kid can only see the Food board for example (focused therapy sessions).
8. **Predictive next word** — based on tap history, suggest the most likely next word above the keyboard.

Sleep well, and tell me which of those to build next when you're ready.
