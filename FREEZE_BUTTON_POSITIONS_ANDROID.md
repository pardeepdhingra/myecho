# Feature Handover: "Freeze Button Positions" (Android)

**Audience:** Android developer implementing parity with the iOS build.
**Status on iOS:** Implemented and verified (Opus build, iPad simulator).
**Cross-platform contract impact:** One new boolean field in `AacSettings`. See [§6 Sync](#6-cloud-sync--backup-contract).

---

## 1. What the feature does (behavior spec)

The communication board shows word buttons in a grid. The **"All"** view lists every
visible word ordered by each word's `position` (left→right, top→bottom). When the user
taps a category chip (e.g. *Feelings*), today the matching words **re-flow to the
top-left**, so a button like *happy* appears in a different on-screen spot in *All* vs
*Feelings*.

This disorients AAC kids — it breaks **motor planning / muscle memory** (a button should
always live in the same place).

**Freeze Button Positions** is an opt-in parent setting (default **OFF**). When **ON** and
a *real category* is selected, every button keeps the **exact grid cell it occupies in the
All view**. Cells whose word is not in the selected category are rendered as **subtle blank
placeholders** instead of being removed — so nothing slides around.

### Scope / exclusions (important)
- Applies **only to real categories.**
- **All**, **Recent**, and **Favorites** keep their current behavior — **never frozen.**
  (Recent is a recency-ordered list; Favorites is a custom-ordered set. Freezing them makes
  no sense.)
- Default is **OFF** — existing users see no change until a parent enables it.

### Visual reference (iOS, "Feelings" selected, freeze ON)
```
Row1: [   ] [   ] [   ] [happy] [   ] [   ] [   ] [   ] ...
Row2: [   ] [ sad ] [angry] [scared] [hurt] [tired] [   ] ...
...
Row N: [   ] [calm] [   ] [love] [   ] ...   <- last row with a Feelings tile
(everything after the last Feelings tile is trimmed away — no empty tail)
```
Blank cells = a pale, almost-invisible rounded square (light fill + very faint border),
**non-interactive** and **skipped by accessibility/TalkBack**.

---

## 2. Data model change

Add one field to the settings model (Android equivalent of `AacSettings`):

| Field | Type | Default | JSON key (camelCase, identical both platforms) |
|---|---|---|---|
| `freezeButtonPositions` | `Boolean` | `false` | `freezeButtonPositions` |

- Must be **backward-compatible**: when decoding older saved/synced settings that lack the
  key, default to `false`. (On iOS: `decodeIfPresent ?? false`. On Android with kotlinx
  Serialization use a property default `= false`; with Gson/Moshi a missing field → default.)
- Persist it wherever the rest of the settings live (DataStore / Room / SharedPreferences —
  whatever the Android app already uses for `AacSettings`).

---

## 3. The layout algorithm (the heart of the feature)

There is **no schema change to words** — words already carry a stable `position: Int`. The
canonical order is **all visible words sorted by `position` ascending** (this is exactly
what the "All" view renders).

When the board renders the grid, decide the cell list as follows:

```
fun boardCells(allVisibleWordsSortedByPosition: List<Word>,
               selectedCategory: String?,        // null = All
               isRecentOrFavorites: Boolean,
               freezeEnabled: Boolean): List<Cell> {

    val freezeActive = freezeEnabled
        && selectedCategory != null
        && !isRecentOrFavorites

    if (!freezeActive) {
        // EXISTING behavior — unchanged.
        // Return the normal filtered+ordered list of word cells (no blanks).
        return normalVisibleWords(selectedCategory).map { Cell.Word(it) }
    }

    // FROZEN behavior:
    // 1. Walk the full "All" order; keep matching words, blank out the rest.
    val cells: List<Cell> = allVisibleWordsSortedByPosition.mapIndexed { index, word ->
        if (word.category == selectedCategory) Cell.Word(word) else Cell.Blank(index)
    }

    // 2. Trailing-trim: drop blanks AFTER the last real tile, so a small top-of-board
    //    category doesn't leave a wall of empty rows / pointless scroll.
    val lastWordIdx = cells.indexOfLast { it is Cell.Word }
    if (lastWordIdx < 0) return emptyList()          // zero matches → empty grid
    return cells.subList(0, lastWordIdx + 1)
}
```

Key rules:
- **Leading and interior blanks are KEPT** (they preserve absolute position).
- **Trailing blanks are TRIMMED** (everything after the last matching tile is removed).
- **Zero matches → empty grid** (no wall of blanks).
- Grid column count, tile size/scale, and spacing are **unchanged** — blanks use the same
  cell footprint as real tiles so the grid stays perfectly aligned.

`Cell` is a small sealed type:
```kotlin
sealed interface Cell {
    data class Word(val word: AacWord) : Cell
    data class Blank(val slotIndex: Int) : Cell   // slotIndex only needs to be a stable key
}
```
Use a **stable key** per cell in the grid adapter / `LazyVerticalGrid` `items(key = …)`:
word cells key on `word.id`; blank cells key on something like `"blank_$slotIndex"`. Stable
keys keep diffing/animations correct.

---

## 4. The blank placeholder cell

Render a cell that occupies the **identical footprint** as a real tile (same width/height
that the grid assigns each cell) so columns line up:
- Background: very light fill, e.g. ~3–4% black (`Color.Black.copy(alpha = 0.035f)` in
  Compose, or `#0A000000`), with an optional ~5% black hairline border.
- Same corner radius as tiles.
- **Not clickable** — no ripple, no tap handler.
- **Excluded from accessibility:** in Compose `Modifier.clearAndSetSemantics {}` /
  `invisibleToUser`; in Views set `importantForAccessibility = NO`. TalkBack must skip empties.
- If the board uses a fixed aspect ratio for tiles (iOS tiles are square,
  `aspectRatio(1)`), the blank must use the **same aspect ratio** so heights match.

> Note: iOS recently made tiles **square** (`aspectRatio(1)`). If Android tiles aren't
> already square, that's a separate parity item — but the blank cell must match whatever
> the real tile's footprint is.

---

## 5. Parent settings UI

Add a toggle in the parent/settings screen (same area as the existing grid/layout toggles
like "Show categories", "Color tiles by category"):

- **Label:** `Freeze button positions`
- **Section header (iOS uses):** `Layout`
- **Footer/help text:**
  > "Keeps each button in the same spot when you filter by a category, so it's easier to
  > find by muscle memory. Empty spaces appear where words from other categories would be."
- Two-way bound to `settings.freezeButtonPositions`; persists immediately like other toggles.

---

## 6. Cloud sync & backup contract

The cross-platform contract serializes the whole `AacSettings` object into the
`settingsJSON` string field of the synced board document (see `CLOUD_SYNC_PLAN.md` §A4).
Because the new field lives inside that object:

- **No structural contract change** — `settingsJSON` still carries the full settings object.
- **Add `freezeButtonPositions` to the `AacSettings` JSON shape on both platforms** so it
  round-trips. JSON key is **`freezeButtonPositions`** (camelCase, identical on iOS/Android).
- **Lenient decode required:** a board synced from an older app (no key) must decode to
  `false`, not crash. (This matches the existing `voiceIdentifier`/ElevenLabs lenient-decode
  rule in §A4.)
- This field is **NOT device-local** — unlike `voiceIdentifier` and the PIN, it SHOULD sync
  (a parent's layout preference should follow their account across devices).
- Please also update `CLOUD_SYNC_PLAN.md` §A4's `AacSettings` line to list the new field
  (and the already-shipped `colorTilesByCategory` + `categoryStyles`, which predate this and
  aren't yet documented there). The exact replacement text is in [§6.1](#61-contract-update-drop-in-for-cloud_sync_planmd-a4) below.

### 6.1 Contract update (drop-in for `CLOUD_SYNC_PLAN.md` §A4)

`CLOUD_SYNC_PLAN.md` §A4 currently lists only the original `AacSettings` fields. It is **out
of date** — it predates three fields that now ship on iOS and must round-trip in
`settingsJSON`. Replace the `AacSettings` bullet in §A4 with the following (keys are
camelCase, **identical on both platforms**):

> - **AacSettings:** `gridColumns`(Int), `speechRate`(Float), `pitchMultiplier`(Float),
>   `showCategoryFilter`, `showQuickPhrases`, `trackUsageHistory`, `showSymbolsInMessageBar`,
>   `showAllVoiceQualities`, `tileScale`(Double), `showRegulationBar`,
>   **`colorTilesByCategory`(Bool)**, **`categoryStyles`(array, see below)**,
>   **`freezeButtonPositions`(Bool)**.
>   - **`voiceIdentifier` is EXCLUDED from sync** (write `null` in `settingsJSON`) — unchanged.
>   - All three new fields use **lenient decode**: a board from an older app that omits any of
>     them must default — `colorTilesByCategory → true`, `categoryStyles → []`,
>     `freezeButtonPositions → false` — and must **not** crash.
>   - **`CategoryStyle`** (element of `categoryStyles`): `id`(UUID string, UPPERCASE),
>     `name`(String, the category name it applies to), `colorName` ∈
>     `{blue,green,orange,pink,purple,teal,yellow,gray}`, `icon`(String, an emoji).
>     Categories without an entry fall back to per-platform defaults.

**Default-value summary (all three new settings fields):**

| Field | Type | Default when missing | Syncs? |
|---|---|---|---|
| `colorTilesByCategory` | Bool | `true` | yes |
| `categoryStyles` | `[CategoryStyle]` | `[]` (empty) | yes |
| `freezeButtonPositions` | Bool | `false` | yes |

> Note: `colorTilesByCategory` and `categoryStyles` are part of the **separate category
> color/icon feature** (already on iOS) — listed here only so the contract is complete. This
> doc's feature is `freezeButtonPositions`.

---

## 7. Edge cases (must handle — all handled on iOS)

| Case | Expected behavior |
|---|---|
| Freeze OFF | Identical to today — filtering reflows to top-left, no blanks. |
| Category with **zero** visible matches | Empty grid (no blanks at all). |
| Empty board | Empty grid. |
| **All** selected (freeze ON) | Shows everything; no blanks (All already includes every word). |
| **Recent** / **Favorites** (freeze ON) | Normal behavior; **never** frozen, no blanks. |
| Toggle freeze while a category is selected | Grid switches between frozen/reflowed **live** (recompute each render; no state reset). |
| Selected category gets deleted/emptied while frozen | Fall back to All (iOS already resets `selectedCategory` when it no longer exists). |
| Vary column count / tile scale | Blanks stay aligned and same-sized as tiles (they derive size from the grid cell, not a fixed value). |
| TalkBack / accessibility | Blank cells are skipped; only real tiles are focusable. |

---

## 8. Test checklist (parity acceptance)

1. **Default OFF:** category filtering still reflows to top-left — no regression, no blanks.
2. Enable in parent settings → return to board.
3. Note a word's on-screen cell in **All** (e.g. *happy*). Tap its category chip → the word
   is in the **same cell**; other cells are subtle blanks; layout does **not** reflow.
4. **Trailing trim:** pick a small category whose words sit near the top → no large empty
   tail / no pointless scroll past the last real tile.
5. **Interior/leading gaps kept:** a word at a later position still sits in its true slot
   with empty cells before it.
6. Tap a blank → nothing happens.
7. **Recent** and **Favorites** with freeze ON → **no blanks**, normal order.
8. Change grid columns (up to max) and tile size → blanks remain aligned and same-sized.
9. TalkBack swipe through grid → blanks skipped.
10. Toggle freeze OFF while a category is selected → grid reflows live.
11. **Persistence:** kill/relaunch app → setting survives.
12. **Sync:** enable on device A, pull on device B → setting carries over; an older board
    (no key) decodes to `false` without crashing.

---

## 9. iOS reference (for behavior parity)

The iOS change touched four files — use them to confirm exact behavior:

| iOS file | What it contains |
|---|---|
| `MyEchoAAC/Models/AACSettings.swift` | `freezeButtonPositions: Bool` (default false), Codable back-compat (`decodeIfPresent ?? false`). |
| `MyEchoAAC/Views/KidModeView.swift` | `BoardSlot` enum (`.word` / `.blank`), `isFreezeActive` guard, `freezeSlotsForSelectedCategory()` (the algorithm in §3, incl. trailing-trim), grid branch. |
| `MyEchoAAC/Views/WordTileView.swift` | `BlankTileView` (the placeholder in §4). |
| `MyEchoAAC/Views/ParentModeView.swift` | The "Layout" section toggle in §5. |
| `MyEchoAAC/Models/AACStore.swift` | `visibleWords(in: null)` = the canonical "All"-ordered source list (read-only; no change). |

**Canonical source list** = visible words sorted by `position` ascending. Make sure the
Android "All" ordering matches this exactly, or frozen positions won't line up with All.
