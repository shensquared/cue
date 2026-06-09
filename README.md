# Cue

Personal iOS + watchOS app for timestamped voice comments on lecture recordings.
See [`SPEC.md`](SPEC.md) for the full design and locked decisions.

## Layout

```
Shared/         Annotation model + WCSession message keys (used by both targets)
iOS/            Phone app: playback, annotation store, WCSession host, transcription
Watch/          Watch app: trigger UI (button + Double Tap), recorder, WCSession client
project.yml     XcodeGen project definition
```

## Prereqs

- Xcode 15+ (full app, not just Command Line Tools)
- `xcodegen` (already installed via Homebrew: `brew install xcodegen`)

## Generate the Xcode project

```
xcodegen generate
open Cue.xcodeproj
```

Re-run `xcodegen generate` after adding or moving source files.

## Bundle identifiers

- iOS app: `mit.shenshen.cue`
- Watch app: `mit.shenshen.cue.watchkitapp`

Set your Apple Developer team in Xcode's "Signing & Capabilities" tab (or
edit `DEVELOPMENT_TEAM` in `project.yml`) before building to device.

## Current state

The full loop is coded but unverified on device. Phone has lecture
import via `.fileImporter` (Files app, so iCloud Drive and Nextcloud's
Files provider both work), a multi-lecture list with swipe-to-delete,
a CSV `ShareLink` once a lecture is active, and an SFSpeechRecognizer
auth prompt on launch. The Watch wraps recording in a short
`WKExtendedRuntimeSession` so the clip survives a wrist drop, then
invalidates the session on stop. Error state on the Watch resets on
the next trigger tap.

Build, install on phone + paired Watch, and exercise the start/stop
loop with a real lecture file to validate the timeline + WCSession
path before adding polish.
