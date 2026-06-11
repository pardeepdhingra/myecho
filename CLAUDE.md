# Vani (वाणी) — Claude Project Instructions

## Project Overview
Vani is a native SwiftUI AAC (Augmentative and Alternative Communication) app for iPad/iPhone. The primary user is a child with communication needs; the secondary user is a parent/therapist who configures the board.

## Key Conventions
- **Primary test target**: iPad (A16) simulator — iPad is the main AAC device. Run `xcodebuild test -scheme MyEchoAAC -destination 'platform=iOS Simulator,name=iPad (A16)'`.
- **Test framework**: Swift Testing (`import Testing`, `@Test`, `#expect`). No XCTest.
- **Persistence**: UserDefaults via `AACStore`. Tests must use `makeIsolatedDefaults()` from `TestSupport.swift`.
- **Board modes**: `.folders` (Motor Plan with core band + folder fringe) and flat (category filter + grid).
- **Core words** (`AACWord.coreCategory`) live in the persistent left band in folder mode — always visible.

## Plan Workflow
Plans live in `.claude/plans/`:
- `todo/`   — upcoming, not yet started
- `active/` — currently being implemented (at most one at a time)
- `done/`   — completed and merged

When starting a new feature: move the plan from `todo/` → `active/`. When merged: move to `done/`.

## Architecture
```
MyEchoAAC/
├── Models/    AACWord, AACStore, AACSettings, MessageComposer, QuickPhrase, SignLanguage
├── Services/  SpeechService, PredictionService, PronunciationService, UsageHistory,
│              BoardBackup, BoardSetStore, CloudSyncService, SignSearchService, etc.
└── Views/     KidModeView (main board), ParentModeView, WordTileView, FolderTileView, …

MyEchoAACTests/   Swift Testing unit tests
MyEchoAACUITests/ XCUITest kid-mode journey tests
```

## Common Commands
```bash
# Build
xcodebuild build -scheme MyEchoAAC -destination 'platform=iOS Simulator,name=iPad (A16)' | xcpretty

# Test
xcodebuild test -scheme MyEchoAAC -destination 'platform=iOS Simulator,name=iPad (A16)' | xcpretty
```
