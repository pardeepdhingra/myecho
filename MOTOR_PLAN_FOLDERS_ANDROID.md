# Feature Handover: "Motor Plan" Folders + Word-Type Colours + Expanded Vocabulary (Android)

**Audience:** Android developer implementing parity with the iOS build.
**Status on iOS:** Implemented (Opus build).
**Cross-platform contract impact:** One new nullable field on `AacWord` (`partOfSpeech`) and two new
`AacSettings` fields (`colorMode`, `boardMode`) — all additive + lenient. See
[§5 Sync](#5-cloud-sync--backup-contract). `schemaVersion` stays **1**.

This came from speech-therapist feedback (the child does well with TD Snap's "Motor Plan"). Three
asks, delivered together:

1. **Folders + fixed positions** — every word has one consistent location, reached by folders, **not**
   scrolling.
2. **Colour by word type** — Fitzgerald Key (nouns, verbs, adjectives, pronouns, joining words…).
3. **More categories** — a broad built-in starter vocabulary.

---

## 1. Folder ("Motor Plan") board — behaviour spec

A new **board mode** replaces the scrolling-grid-with-category-chips as the default.

- **`boardMode = folders` (new default):**
  - **Home page** = a fixed grid of:
    1. **Core words** — every visible word whose `category == "Core"`, ordered by `position`.
    2. **Folder tiles** — one per *distinct non-core category that has ≥1 visible word*, in
       first-appearance order (by min `position`). A folder tile shows the category's icon + name and
       is visually distinct from a word tile (e.g. dashed border + folder badge). Tapping it opens
       that folder.
    3. (Optional) a **Favorites** folder tile at the end when any visible favourite exists.
  - **Folder page** = the category's words, ordered by `position`, rendered in a **fixed grid**.
    **Hidden words are kept as blank placeholder cells** (so visible words never shift — muscle
    memory), with **trailing blanks trimmed** (same rule as the Freeze feature). A **Home button**
    returns to the home page. The message bar + Speak/Clear/Backspace controls stay fixed across pages.
  - **No category-chip filter** in this mode; navigation is via folder tiles. **Recent** is not shown
    (recency reorders — breaks motor planning); **Favorites** is optional as above.
  - Each page is a fixed grid. Scrolling **within** a folder is acceptable graceful degradation if a
    folder overflows (scrolling reveals more cells but never *reorders* them). Folders are sized to
    fit where possible.
- **`boardMode = classic`:** the original scrolling grid + category chips + "Freeze button positions".
  Keep it working unchanged as a fallback a parent can switch to.

### Canonical ordering (must match iOS exactly)
- Core words: `words.filter { visible && category == "Core" }.sortedBy(position)`.
- Folder list: distinct `category` of `words.filter { visible && category != "Core" }` in ascending
  `position` order, deduped by first appearance.
- A folder's cells: `words.filter { category == X }.sortedBy(position)`, mapping **visible → tile**,
  **hidden → blank**, then trim trailing blanks. Zero visible → empty grid.

---

## 2. Word-type colours (Fitzgerald Key)

Add an optional `partOfSpeech` to the word model and a colour **mode** to settings.

| `partOfSpeech` value | Meaning | Default tile colour |
|---|---|---|
| `noun` | thing | `orange` |
| `verb` | action | `green` |
| `adjective` | describing | `blue` |
| `pronoun` | I/you/it/my… | `yellow` |
| `social` | hello/please/sorry… | `pink` |
| `question` | what/where/who… | `teal` |
| `joiningWord` | and/but/in/on… | `purple` |
| (null / untagged) | — | falls back to the word's own `colorName` |

Colours map to the existing 8-value `colorName` palette (`gray` is the untagged fallback only).

### Colour mode (`AacSettings.colorMode`)
- `byCategory` (**default**) — every tile in a category shares the category's colour (today's behaviour).
- `perWord` — each tile uses its own `colorName`.
- `byWordType` — tile colour = `partOfSpeech.defaultColor`, falling back to `colorName` when untagged.

Tile-colour resolution (match iOS `AACStore.tileColor`):
```
when (colorMode) {
  byCategory -> resolvedCategoryStyle(word.category).color
  perWord    -> word.colorName.color
  byWordType -> (word.partOfSpeech?.defaultColor ?: word.colorName).color
}
```

---

## 3. Expanded starter vocabulary

iOS ships a broad, folder-organised default board (`StarterVocabulary`) where **every** word is tagged
with `category` (folder), `partOfSpeech`, `colorName` (= the word type's colour), and a sequential
`position`. Folders: **Core** (home), People, Food, Drink, Actions, Describing, Feelings, Body, Places,
Play, School, Clothes, Social, Questions, Joining words.

- **Labels are unique across the whole set** so an idempotent, skip-duplicates merge never creates
  duplicates.
- Fresh installs get the full set. Existing users keep their board and can **additively merge** missing
  words (skip by case-insensitive label, append with fresh positions so nothing moves).
- Match the same words/folders/word-types on Android so a cross-platform restore lines up. (The exact
  list is in `MyEchoAAC/Services/StarterVocabulary.swift`.)

---

## 4. Parent settings UI

- **Layout** section: a **Board layout** picker (`Folders (Motor Plan)` / `Classic scroll`). Show the
  "Freeze button positions" toggle only in Classic.
- **Colors** section: a **Color tiles** picker (`By category` / `Per word` / `By word type`). When
  `By word type`, show a small legend (swatch + label per word type). Keep the category colour/icon
  editor.
- **Edit word**: a **Word type** picker (None + the 7 values). Disable the per-word **Color** picker
  unless `colorMode == perWord`.

---

## 5. Cloud sync & backup contract

See `CLOUD_SYNC_PLAN.md` §A4 (updated). Summary of what Android must serialize into the synced
`board/current` JSON strings:

| Field | Location | Type | Default when missing | Syncs? |
|---|---|---|---|---|
| `partOfSpeech` | `AacWord` | enum (see §2), nullable | `null` (untagged) | yes |
| `colorMode` | `AacSettings` | `{byCategory,perWord,byWordType}` | `byCategory` | yes |
| `boardMode` | `AacSettings` | `{folders,classic}` | `folders` | yes |

- All **lenient-decode**: a board from an older app missing any key must default, not crash.
- **Legacy migration:** if `colorMode` is absent but the old `colorTilesByCategory` bool is present,
  map `true → byCategory`, `false → perWord`.
- JSON keys are camelCase and **identical on both platforms**: `partOfSpeech`, `colorMode`, `boardMode`.
- These are user preferences that **do** sync (like `freezeButtonPositions`) — not device-local.

---

## 6. Edge cases (handled on iOS)

| Case | Expected |
|---|---|
| Folder with zero visible words | Not shown as a folder tile; if open and emptied, fall back to Home. |
| Hide a word inside a folder | Its cell becomes a blank placeholder; other words **do not move**. |
| Add a new word | Gets a higher `position` → appears at the end; existing words don't shift. |
| `Core` category empty | Home page shows only folder tiles. |
| Switch Folders ↔ Classic | Live; no data change. Classic keeps chips + freeze. |
| Untagged word in `byWordType` | Falls back to its `colorName`; never blank/crash. |
| Older synced board (no new keys) | Decodes with defaults above. |

---

## 7. Test checklist (parity acceptance)

1. Default board mode = **Folders**; home shows Core words + a folder per category.
2. Open a folder → fixed grid; note a word's cell; **hide an earlier word** → remaining words don't
   move; **add a word** → existing words don't shift.
3. Home button returns; navigate Home ↔ folder repeatedly → no reflow.
4. Colour modes switch live; **By word type** matches the §2 table; untagged falls back.
5. Expanded vocabulary present with correct folders/word-types/colours; merge is idempotent.
6. Switch to **Classic** → original scroll board + chips + freeze still work.
7. **Sync:** set `colorMode`/`boardMode`/`partOfSpeech` on device A → device B reflects them; an older
   board (missing keys) decodes to defaults without crashing; a board created on Android restores on
   iOS and vice-versa.

---

## 8. iOS reference

| iOS file | What it contains |
|---|---|
| `Models/AACWord.swift` | `PartOfSpeech` enum (+ `defaultColor`), `partOfSpeech` field, `coreCategory`. |
| `Models/AACSettings.swift` | `ColorMode` + `BoardMode` enums; `colorMode`/`boardMode`; legacy `colorTilesByCategory` migration. |
| `Models/AACStore.swift` | `tileColor(for:)` 3-way switch; `defaultWords = StarterVocabulary.words`; `mergeStarterVocabulary()`. |
| `Services/StarterVocabulary.swift` | The full tagged starter vocabulary + folder taxonomy. |
| `Views/KidModeView.swift` | Folder navigation: `openFolder`, `coreWords`, `folderCategories`, `folderSlots`, `homePage`, `folderPage`, `folderHeader`. |
| `Views/FolderTileView.swift` | The folder tile. |
| `Views/ParentModeView.swift` | Board-layout picker, color-mode picker + `wordTypeLegend`. |
| `Views/EditWordView.swift` | Word-type picker; per-word colour gating (`colorMode != perWord`). |

---

## 9. TD Snap "Motor Plan" quality pass (follow-up — match this on Android)

A second round made the folder board look/behave like **TD Snap Motor Plan**, and these are now the
**defaults for new installs**. New fields are additive + lenient; `schemaVersion` stays **1**.

### 9.1 New synced fields
| Field | Location | Type / values | Default (decode) | New-install default |
|---|---|---|---|---|
| `symbolName` | `AacWord` | String? (bundled asset name `sym_…`) | `null` | per starter word |
| `tileStyle` | `AacSettings` | `{outlined,filled}` | `outlined` | `outlined` |
| `gridPreset` | `AacSettings` | `{size30,size40,size66,custom}` | `size40` | `size40` |
| `gridRows` | `AacSettings` | Int (used when `custom`) | `5` | `5` |
| `coreColumns` | `AacSettings` | Int 0–2 | `2` | `2` |
| `categoryOrder` | `AacSettings` | [String] (folder order) | `[]` | `[]` |
| `colorMode` | `AacSettings` | (unchanged values) | `byCategory` | **`byWordType`** |

Grid preset dimensions (columns × rows): **size30 = 6×5, size40 = 8×5, size66 = 11×6**.

### 9.2 Persistent-core + fringe layout (folder board)
- The board is a **fixed `columns × rows` grid that never scrolls** (fills the screen; sizes tiles via
  available space). Overflow **paginates sideways** (swipe), it does not scroll.
- **Leftmost `coreColumns` columns** = the **persistent core**: core-category words (visible, by
  position), **identical on every page**. Core words beyond the band's capacity (small grid /
  `coreColumns == 0`) spill to the **start of the home fringe** so none are lost.
- **Remaining columns** = **fringe**: folder tiles on home (in `categoryOrder`, then first-appearance),
  or the open folder's words (hidden → blank to hold the slot). A nav bar shows **Home** + breadcrumb.
- Core vocabulary is curated to ~10 words so it fits one 2-column band; match the iOS
  `StarterVocabulary` Core set and folder placement.

### 9.3 Tile style
- `outlined` (default): **near-white fill + a thick word-type/category-coloured border** (the TD Snap
  look). `filled`: the older soft pastel fill. Folder tiles use a dashed coloured border.
- Tile artwork priority (unchanged intent, now incl. symbols): **photo → sign video → bundled picture
  symbol (`symbolName`) → emoji**. A custom **photo always wins**.

### 9.4 Picture symbols
- Built-in words use a bundled professional symbol set (**Mulberry**, CC BY-SA 4.0 — commercial-safe;
  attribution required) shipped as named assets (`sym_<word>`). Android must bundle the **same named
  assets** so `symbolName` renders identically. Parents can pick a symbol when adding/editing a word;
  clearing it falls back to emoji.

### 9.5 Customization
- **Folder icons**: per-category style editor (emoji or a `sym_…` symbol) — already present.
- **Folder order**: drag-to-reorder writing `categoryOrder` (sequence = grid placement; no free-cell
  placement).

### 9.6 Parity checklist (additions)
1. New install defaults to outlined tiles + word-type colours + a Motor Plan grid + persistent core.
2. Persistent core column is identical on home and inside every folder; overflow paginates (no scroll).
3. Grid size 30/40/66 resizes tiles to fit; `coreColumns` reserves the left band.
4. Reorder folders → board order changes; folder icon edits show on the tile.
5. Built-in words show picture symbols; a custom **photo overrides** the symbol; clearing a symbol
   falls back to emoji.
6. All new keys lenient-decode to the defaults above; cross-platform restore lines up.
