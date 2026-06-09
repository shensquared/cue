# Commentator

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
open Commentator.xcodeproj
```

Re-run `xcodegen generate` after adding or moving source files.

## Bundle identifiers

- iOS app: `mit.shenshen.commentator`
- Watch app: `mit.shenshen.commentator.watchkitapp`

Set your Apple Developer team in Xcode's "Signing & Capabilities" tab (or
edit `DEVELOPMENT_TEAM` in `project.yml`) before building to device.

## Current state

Stubs for the full loop are in place. Not yet wired up:

- File import for lecture audio (uses a placeholder `LecturePicker`)
- CSV export action in the UI
- Error surfacing on the Watch
- Lecture browsing / multi-lecture UI on the phone

Build, install on phone + paired Watch, and exercise the start/stop loop
with a local m4a/mp3 to validate the timeline + WCSession path before
adding polish.
