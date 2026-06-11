# Plan: ARASAAC Symbol Library Integration

**Status**: todo  
**Priority**: TD Snap parity #3

## Goal
Integrate the ARASAAC open symbol set (CC BY-NC-SA license) so parents can search and download professional symbols for any word. Currently the bundled set is small and custom photos require manual work.

## Key decisions to make
- ARASAAC API endpoint: `https://api.arasaac.org/api/pictograms/`
- Cache downloaded images in `ImageStore` or a separate `SymbolCache`.
- Attribution: ARASAAC requires credit — show in About screen.
- License enforcement: NC (non-commercial) — document for App Store.

## Rough scope
- Extend `SymbolPickerView` to include ARASAAC search tab.
- `AARASAACService` for API calls + caching.
- `AACWord.symbolSource` to track origin (bundled / arasaac / user-photo).
