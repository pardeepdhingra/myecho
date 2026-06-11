# Plan: Switch Scanning

**Status**: todo  
**Priority**: TD Snap parity #4 — core accessibility feature

## Goal
Row/column scanning with external-switch and full-screen-tap support, matching TD Snap's primary accessibility feature.

## Rough scope
- `ScanningEngine` — manages scan state (row highlight → column highlight → activate).
- `AACSettings.scanningEnabled`, `.scanInterval`, `.scanMode` (.rowColumn / .linear).
- Overlay layer in `KidModeView` that draws highlight frames without disrupting tap targets.
- External switch: `UIAccessibility.registerGestureConflictWithZoom` or `UIEvent` monitoring.
- Full-screen-tap mode: any tap advances the scan cursor.
