# Plan: Board Sets (Home, School, Therapy)

**Status**: done  
**Merged**: 2026-06-11 (commit a0da624)

## What was built
- `BoardSetStore` — save/load/rename/overwrite named full-board snapshots as `.vaniboard` JSON files (same format as backup, with embedded photos).
- `BoardSetsView` — Parent → Board → Board sets UI.
- Up to N named sets; the live board remains the single synced board.

## Files changed
- `Services/BoardSetStore.swift` (new)
- `Views/BoardSetsView.swift` (new)
- `Views/ParentModeView.swift` (new navigation entry)
- `MyEchoAACTests/BoardSetStoreTests.swift` (new)
