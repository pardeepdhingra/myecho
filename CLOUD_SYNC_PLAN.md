# Vani — Optional Account + Cloud Backup + Multi-Device Sync (Cross-Platform Plan)

> **Status: PLAN / not yet executed.** This is the **single shared plan for BOTH the iOS and Android
> apps**. The **Part A — Shared Cloud Contract** is the cross-platform agreement both apps MUST
> implement identically; if iOS and Android agree on Part A, a board created on one platform restores
> on the other. Parts C/D are the per-platform build. This supersedes the earlier iOS-only
> `CLOUD_SYNC_PLAN.md` and resolves all of its open questions.
>
> Owners: **iOS agent** builds Part D; **Android agent** builds Part C; both code against Part A & B.

## Goal
Let a parent **optionally** sign in with an email account and have their **board, quick phrases,
settings, stats, word photos, and sign-language videos** backed up to the cloud and **automatically
synced across devices**. Both apps must keep working **fully offline with no account**, exactly as
today.

**Locked decisions:** Backend = **Firebase** (Auth + Firestore + Storage). Sync = **automatic
background sync**, whole-board **last-write-wins** by `(updatedAtClient, deviceId)`, pull on sign-in.
**Sign-language videos are included.** Shared login = **Email/Password** (Android also offers
email magic-link; iOS also offers Sign in with Apple — all resolve to one Firebase `uid`).
**One Firebase project hosts both apps**, sharing Auth + Firestore + Storage.

---

## Part A — Shared Cloud Contract (iOS + Android must match EXACTLY)

### A1. Auth
- Firebase Authentication. Shared provider: **Email/Password**. Platform extras: Android **email
  magic-link**, iOS **Apple** — all map to a Firebase `uid`. No anonymous auth.
- Account is **optional**: no Firebase activity until the user explicitly signs in. Local storage is
  the offline source of truth. **Sign-out never wipes local data.** The parent **PIN never syncs.**

### A2. Firestore data model (per user)
Binaries are kept **out** of Firestore (1 MB doc limit) — board JSON in a doc, assets in Storage.

```
/users/{uid}                   { email?, createdAt, lastDeviceId, schemaVersion }
/users/{uid}/board/current     {
    schemaVersion: 1,
    updatedAt: serverTimestamp,        // server clock — ordering/debug only
    updatedAtClient: Timestamp,        // client clock at write — LWW authority + offline
    deviceId: String,                  // which device wrote this revision
    wordsJSON: String,                 // JSON-encoded [AacWord]
    quickPhrasesJSON: String,          // JSON-encoded [QuickPhrase]
    settingsJSON: String,              // JSON-encoded AacSettings (voiceIdentifier nulled — see A4)
    usageEntriesJSON: String,          // JSON-encoded [UsageEntry]  (stats)
    spokenSentencesJSON: String        // JSON-encoded [String]      (stats)
  }
/users/{uid}/assets/{filename} {       // one doc per binary, for reconciliation + GC
    filename, kind: "image"|"signVideo"|"signThumb", storagePath, updatedAtClient, deviceId, sizeBytes
  }
```

- Board = **one doc** (`board/current`) with **JSON-as-String** fields, so each platform serializes
  its native models directly and stays schema-stable as models gain fields.
- **Conflict policy:** whole-board **last-write-wins**, authority = `(updatedAtClient, deviceId)`.
  A device applies a remote board only if remote `updatedAtClient` **>** its local high-water mark
  **and** the writing `deviceId` **is not itself**.

### A3. Storage layout (keyed by the SAME local filenames — no path rewriting on restore)
```
users/{uid}/word-images/{uuid}.jpg     // word photos (JPEG, ~max 800px)
users/{uid}/sign-videos/{uuid}.mp4     // sign-language videos (H.264 MP4, ~1–5 MB)
users/{uid}/sign-videos/{uuid}.jpg     // video thumbnail
```
The local subfolder (`word-images` / `sign-videos`) maps 1:1 to the Storage subfolder. On pull, each
object is written to the matching local folder under the same filename; `imagePath` /
`signVideoPath` (filename-only) resolve unchanged.

### A4. JSON shapes — exact keys (camelCase) and enum raw values  ⚠️ identical on both platforms
- **AacWord:** `id`(UUID string, UPPERCASE), `label`, `phrase`, `symbol`, `category`,
  `colorName` ∈ `{blue,green,orange,pink,purple,teal,yellow,gray,red,indigo,brown,mint,cyan,rose,coral}`
  (the last 7 were added so categories don't repeat colours; **lenient decode** — an app that doesn't
  know a value should fall back to `gray`), `position`(Int),
  `isVisible`(Bool), `imagePath`(String?), `isFavorite`(Bool), `sourcePackId`(String?),
  `favoritePosition`(Int?), `signVideoPath`(String?), `signLanguage` ∈ `{auslan,asl}` (nullable),
  **`partOfSpeech`** ∈ `{noun,verb,adjective,pronoun,social,question,joiningWord}` (nullable —
  lenient decode, default `null`/untagged). Drives tile colour when `colorMode == byWordType`.
  **`symbolName`**(String?, nullable) — name of a bundled picture-symbol asset (e.g. `sym_apple`).
  Both platforms must ship the same named symbol assets for it to render; a custom **photo always
  takes priority** over the symbol, which takes priority over the emoji.
  - **Reserved category:** `category == "Core"` marks words shown on the **home page** of the folder
    board (see `boardMode` below). Every other distinct `category` is a folder. (`"Core"` is just a
    string value — no schema change.)
- **QuickPhrase:** `id`, `text`, `position`, `mode` ∈ `{speak,startSentence,regulation}`,
  `sourcePackId`(String?), `regulationKind` ∈ `{calm,help,stop}` (nullable).
- **AacSettings:** `gridColumns`(Int), `speechRate`(Float), `pitchMultiplier`(Float),
  `showCategoryFilter`, `showQuickPhrases`, `trackUsageHistory`, `showSymbolsInMessageBar`,
  `showAllVoiceQualities`, `tileScale`(Double), `showRegulationBar`,
  `categoryStyles`(array of `CategoryStyle`), `freezeButtonPositions`(Bool),
  **`colorMode`** ∈ `{byCategory,perWord,byWordType}`, **`boardMode`** ∈ `{folders,classic}`,
  **`tileStyle`** ∈ `{outlined,filled}`, **`gridPreset`** ∈ `{size30,size40,size66,custom}`,
  **`gridRows`**(Int, used when `gridPreset == custom`), **`coreColumns`**(Int 0–4),
  **`categoryOrder`**([String], explicit folder order; empty = first-appearance),
  **`hiddenCategories`**([String], folders hidden from the kid board; words kept, reversible).
  - **`voiceIdentifier` is EXCLUDED from sync** (write `null` in `settingsJSON`): it's an
    iOS-AVSpeech-id vs Android-TTS-name and is meaningless cross-device. Each platform keeps its own
    local voice choice; on apply, **preserve the local `voiceIdentifier`**.
  - ElevenLabs / natural-voice fields are removed on both apps; ignore if present (lenient decode).
  - **`colorMode` supersedes the old `colorTilesByCategory` boolean.** Lenient migration on decode:
    if `colorMode` is present use it; else if legacy `colorTilesByCategory` is present map
    `true → byCategory`, `false → perWord`; else default `byCategory`.
  - **Lenient defaults** (board from an older/other app omitting a key): `colorMode → byCategory`,
    `boardMode → folders`, `freezeButtonPositions → false`, `categoryStyles → []`,
    `tileStyle → outlined`, `gridPreset → size40`, `gridRows → 5`, `coreColumns → 2`,
    `categoryOrder → []`, `symbolName → null`. Must **not** crash. (Note: a brand-new install's
    *creation* default for `colorMode` is `byWordType` — the TD Snap look — but the decode-time
    fallback for a board that predates the key stays `byCategory`.)
  - **`CategoryStyle`** (element of `categoryStyles`): `id`(UUID string, UPPERCASE), `name`(String,
    the category it applies to), `colorName` ∈ `{blue,green,orange,pink,purple,teal,yellow,gray}`,
    `icon`(String, an emoji).
- **UsageEntry:** `id`, `wordId`, `label`, `timestamp` = **ISO-8601 UTC string (RFC 3339)**, e.g.
  `2026-06-09T12:00:00Z`. (Android stores epoch-millis `Long` locally and maps ↔ ISO-8601 via
  `java.time.Instant`; iOS uses `ISO8601DateFormatter`.)
- **`schemaVersion = 1`.** A device that reads a doc with a **higher** `schemaVersion` must **refuse
  to apply** it and prompt to update the app (explicit check — lenient JSON decoders won't throw).
- **Excluded from sync (device-local):** parent **PIN**, `voiceIdentifier`.

### A5. Security rules (publish in Firebase Console)
```
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      match /{document=**} { allow read, write: if request.auth != null && request.auth.uid == uid; }
    }
  }
}
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{uid}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid
                         && request.resource.size < 10 * 1024 * 1024;
    }
  }
}
```

---

## Part B — Sync engine semantics (identical behavior; each platform implements natively)

1. **Push (local → remote):** observe the 5 local stores (words, settings, quickPhrases,
   usageEntries, spokenSentences); **debounce ~3s** so rapid edits coalesce; then write
   `board/current` (the 5 JSON strings + `updatedAtClient = max(now, highWaterMark+1)` + `deviceId` +
   `schemaVersion`). Then **diff referenced asset filenames vs the remote asset index**: upload new
   photos/videos/thumbs, **delete remote assets + their `assets/{filename}` docs that are no longer
   referenced by any word (asset GC).** Update profile `lastDeviceId`. Persist local
   `lastUpdatedAtClient` + `lastContentHash`.
2. **Echo guard (prevents restore→re-upload loops):** an `isApplyingRemote` flag **plus** a persisted
   **content hash** of the board+stats JSON (hash excludes `updatedAt*`/`deviceId`). `applyRemote`
   writes the pulled board's hash to `lastContentHash` **before** releasing, so the debounced push
   that the local re-emission triggers sees "no change" and no-ops.
3. **Pull (remote → local):** snapshot-listener on `board/current`. Ignore the event when
   `deviceId == self`, `updatedAtClient <= highWaterMark`, `contentHash == lastContentHash`, or it's a
   pending local write. Otherwise: **download all referenced assets first**, decode the JSON,
   **preserve local `voiceIdentifier`**, then `replaceAll` board + `importAll` stats; persist
   `lastUpdatedAtClient` + `lastContentHash`.
4. **First sign-in reconcile (one-time, per uid):** no remote board ⇒ **push** local up (seed);
   remote exists & local is the default board ⇒ **pull**; remote exists & local **non-default** ⇒
   one-time prompt **"Use cloud board"** (pull, overwrite local) vs **"Keep this device's board"**
   (push, overwrite cloud). **No silent word-list merge** (positions/favorites/sourcePackId make union
   unsafe). Same wording on both platforms.
5. **Offline / retry:** Firestore offline-persistence is ON. Storage uploads do **not** queue offline
   → retry on foreground / next debounced push / "Sync now". Failures set `status = error`, never
   block the UI. Ordering: **write the Storage object before the Firestore pointer/board doc** so a
   reader never references a missing asset.
6. **Asset GC:** on every push, remote assets (+ meta docs) no longer referenced by any word are
   deleted.

---

## Part C — Android build  (`com.pardeepdhingra.vani`, branch `feature/cloud-sync` → PR)

Firebase is **conditionally enabled**: apply the `com.google.gms.google-services` plugin only when
`app/google-services.json` exists; at runtime, if `FirebaseApp` isn't initialized the cloud layer
reports `Disabled` (build stays green, app fully offline). Add `google-services.json` to `.gitignore`.

- **Deps** (`gradle/libs.versions.toml` + `app/build.gradle`): Firebase BoM, `firebase-auth`,
  `firebase-firestore`, `firebase-storage`, `kotlinx-coroutines-play-services`.
- **New package `com.pardeepdhingra.vani.cloud`:**
  - `DeviceId` — stable per-install UUID in Prefs (`vani.deviceId.v1`).
  - `CloudContract` — the Part A DTOs + codec (build/parse the `board/current` field map; map
    `UsageEntry` Long↔ISO-8601; null out `voiceIdentifier`; content hash).
  - `CloudAuth` — `FirebaseAuth` wrapper; `authState: StateFlow<AuthState>`; password sign-in/up,
    reset, magic-link send/complete, sign-out.
  - `FirestoreClient`, `StorageClient` — async wrappers (board read/write, asset-index read/write/
    delete, Storage put/get/delete) via `await()` on `Dispatchers.IO`; `boardUpdates(uid): Flow`.
  - `CloudSyncService` — the Part B engine; `ui: StateFlow<SyncUiState>`.
  - `ui/parent/AccountSyncSection.kt` — Account UI.
- **Edits:** `data/Prefs.kt` (+sync keys, `getLong/putLong`); `usage/UsageHistory.kt`
  (`replaceAll(entries, sentences)`); `media/SignVideoStore.kt` (`writeMp4(filename, bytes)` + write
  downloaded thumbnail); reuse `ImageStore.writeJpeg/purgeAll` + `AacStore.replaceAll`;
  `AppContainer.kt` (resolve deviceId, build cloudAuth+cloudSync, `start()` in init);
  `MainActivity.kt` (magic-link deep link in `onCreate`/`onNewIntent`); `ui/parent/ParentBoardTab.kt`
  ("Account & Sync" section above the existing Backup section); `AndroidManifest.xml`
  (`MainActivity launchMode="singleTask"` + App-Links `intent-filter autoVerify=true`).

## Part D — iOS build  (`MyEchoAAC/`, aligned to Part A)

- **Deps:** SPM `firebase-ios-sdk` → FirebaseAuth/Firestore/Storage. `FirebaseApp.configure()` first
  in `MyEchoAACApp.init`. Build guarded so it compiles without `GoogleService-Info.plist`.
- **New `Services/`:** `DeviceID.swift`; `SyncPayload.swift` (Codable → Part A shapes, ISO-8601,
  content hash, `voiceIdentifier` nulled); `AuthService.swift` (email + Apple); `FirestoreClient.swift`
  (actor); `StorageClient.swift` (actor); `CloudSyncService.swift` (Combine observers + 3s debounce +
  `isApplyingRemote` + content-hash guard + asset GC + first-link). **`Views/`:** `AccountView.swift`
  + `AuthSheet.swift`.
- **Edits:** `AACStore.replaceAll(words:quickPhrases:settings:)`; `UsageHistory.importAll(entries:
  spokenSentences:)`; add an **"Account"** tab in `ParentModeView` (local Backup section stays).
  Reuse `ImageStore` / `SignVideoStore` / `BoardBackup`.

## Part E — Firebase provisioning (shared; human-only; code won't sync until done)
1. **One** Firebase project. Add **both** an iOS app and an Android app, both bundle/appId
   `com.pardeepdhingra.vani`, so Auth + Firestore + Storage are shared and boards cross platforms.
   `GoogleService-Info.plist` → iOS target; `google-services.json` → Android `app/`.
2. Auth: enable **Email/Password**; **Email-link** (Android); **Apple** (iOS).
3. Create Firestore (production) + Storage; publish the A5 rules.
4. Magic-link only (Android): enable Hosting (or custom domain), add it to Auth "Authorized
   domains", host `/.well-known/assetlinks.json` with the Android app's release signing SHA-256, set
   that domain as the `ActionCodeSettings` continue URL. Add the Android SHA-1/SHA-256 to the Firebase
   Android app. (iOS Apple sign-in needs the Sign in with Apple capability + team `ZM63VS564M`.)

## Part F — Phased rollout (both platforms)
- **Phase 1 — auth + manual transfer:** deps, DeviceId, payload/codec, Auth, Firestore/Storage
  clients, store `replaceAll`/`importAll`, Account UI with sign in/out + **"Sync now"** (push) +
  **"Restore from cloud"** (pull). Deterministic buttons validate transfer incl. photos + sign videos.
- **Phase 2 — full auto-sync:** observers + 3s debounce + echo guard + pull-on-sign-in + first-link
  prompt + live status indicator.

## Part G — Verification
- **Builds green with no Firebase config** (cloud `Disabled`, app offline): Android `./gradlew
  assembleDebug` + unit/instrumented tests pass; iOS builds without the plist.
- **Engine unit tests** (fake Firestore/Storage + in-memory storage + virtual clock): echo guard
  (apply remote → advance past debounce ⇒ **0 writes**); local edit ⇒ 1 board write + correct asset
  upload/GC, `updatedAtClient` increases; remote newer/other-device ⇒ applied; remote older/own ⇒
  ignored; first-link branches incl. conflict; ISO-8601 round-trip; `voiceIdentifier` preserved.
- **Two devices on one account** (per platform AND cross-platform): edit word + photo + sign video on
  A → B reflects within seconds & downloads assets; offline edit + reconnect → propagate + remote
  asset GC; stats propagate; sign-out still works offline; never-sign-in = no network calls.
  **Cross-platform:** board created on iOS restores on Android and vice-versa (validates Part A).

## Risks / limits
- Whole-board **LWW**: concurrent edits on two devices → newer wins, loser's edits overwritten.
  Acceptable for single-family use; per-word merge out of scope (v2 could use a Firestore transaction
  on the board doc rejecting stale-base writes).
- **snapshot size:** the board doc holds JSON strings only (small); assets upload once each and are
  GC'd when unreferenced — cheap.
- **Magic-link** needs the Hosting/App-Links setup; **password** sign-in works immediately without it.
- Firestore offline-persistence fires the listener from cache + server → handled by the
  `deviceId` / `hasPendingWrites` / hash filters.
