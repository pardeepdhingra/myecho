# My Echo AAC

My Echo AAC is a native SwiftUI AAC starter app for a child-first communication board.

## Current app

- Kid mode with a large AAC grid.
- Tap a word to hear it immediately.
- Message bar for building phrases.
- Speak, clear, and backspace controls.
- Parent mode for grid size, categories, word editing, visibility, and voice settings.
- Local persistence with `UserDefaults`.
- Offline speech using `AVSpeechSynthesizer`.

## Voice strategy

The app currently uses Apple's built-in text-to-speech because AAC needs to be fast, reliable, and available without internet.

ElevenLabs can be added as an optional online voice later, but do not place the ElevenLabs API key in the iOS app. Native app binaries can be inspected, and any bundled key should be treated as exposed.

When we add ElevenLabs, put the key in a small backend/proxy service:

```bash
ELEVENLABS_API_KEY=your_key_here
```

The intended local file is `VoiceProxy/.env`; it is ignored by git. `VoiceProxy/.env.example` shows the variables to use.

The iOS app should only store the proxy URL and selected voice ID, not the API key.

## Build

```bash
xcodebuild \
  -project MyEchoAAC.xcodeproj \
  -scheme MyEchoAAC \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath DerivedData \
  build
```

## Next voice step

Add a voice proxy endpoint like:

```text
POST /speak
{ "text": "I want play", "voiceId": "..." }
```

The proxy calls ElevenLabs with `ELEVENLABS_API_KEY` and returns audio data to the app.
