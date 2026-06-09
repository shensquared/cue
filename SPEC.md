# Lecture Annotation App — Workflow Spec

A personal iOS + watchOS app for adding timestamped voice/text comments to your own
lecture recordings, hands-free, while listening through AirPods.

---

## Concept

Play a lecture recording on the iPhone (heard through AirPods). At any moment, trigger
from the Apple Watch to pause playback and capture a spoken comment via the Watch mic.
Each comment is pinned to the exact position in the lecture ("master timestamp") so it
can be reviewed or jumped to later.

---

## Design decisions (and why)

**Watch is the trigger, not AirPods.**
iOS gives third-party apps no general "AirPods stem gesture" API — a stem press is
hardwired to system actions (play/pause, next, previous). Using the Watch as the trigger
sidesteps this entirely and gives precise start/stop control.

**Explicit tap / Double Tap, not wrist-raise.**
watchOS exposes no real "wrist raised / lowered" event — only app lifecycle
(active/inactive), which is coarse, depends on a user setting to reactivate the app,
suspends the app after ~2 minutes of inactivity, and misfires on incidental glances.
That breaks the "sparse comments across a long lecture" rhythm. An explicit tap (any
watch) or Double Tap pinch (Series 9 / Ultra 2+) is reliable and precise.

**Phone is the single source of truth.**
The phone owns the lecture file, the playback timeline, and the annotation store. The
Watch is a precise remote + mic. This keeps state from drifting out of sync and keeps
the Watch app trivial.

**Comment audio quality note (AirPods mic, if ever used instead of the Watch).**
Bluetooth mics historically drop to HFP (phone-call quality) when recording. iOS 26 adds
`AVAudioSessionCategoryOptions.bluetoothHighQualityRecording` for much better AirPods
capture, but it requires the H2 chip (AirPods 4 / Pro 2 / Pro 3). Since playback is
paused during a comment, the old "playback degrades while mic is live" problem does not
apply here. The chosen design uses the **Watch mic**, avoiding this altogether.

---

## Components

- **iPhone app** — owns the lecture file, master playback timeline, and annotation
  store. Plays audio out to AirPods.
- **Watch app** — the trigger (tap / Double Tap) and the comment mic. Captures the
  spoken comment.
- **Link** — WatchConnectivity (`WCSession`) for messages between the two; both reachable
  while a session is live.

---

## Data model — one annotation

| Field              | Description                                            |
|--------------------|--------------------------------------------------------|
| `masterTimestamp`  | Playback position in the lecture, in seconds (e.g. 412.3) |
| `commentAudioFile` | Path to the recorded comment clip (optional)           |
| `transcript`       | Dictated text of the comment (optional)                |
| `createdAt`        | Wall-clock time the comment was made                   |
| `lectureID`        | Which lecture file this belongs to                     |

Keep audio, transcript, or both — see "Decisions to lock," item 1.

---

## Core loop

1. Load lecture on phone; user starts playback (from phone or a "play" on the Watch).
   Phone is the timeline source of truth.
2. Lecture plays through AirPods. Watch shows a single **Comment** control.
3. User triggers (tap / Double Tap) → Watch sends `startComment` to phone.
4. Phone pauses playback, reads `player.currentTime`, holds it as the pending
   `masterTimestamp`, sends `ack` back to the Watch (with haptic confirm).
5. Watch records the comment via its mic — voice clip and/or live dictation.
6. User triggers again → Watch stops capture, sends `endComment` to phone with the
   transcript (and transfers the audio clip if audio is being kept).
7. Phone writes the annotation record (`masterTimestamp` + comment payload), then
   resumes playback from the held position.
8. Repeat. A review screen later lists annotations sorted by `masterTimestamp`, each
   tappable to jump the lecture to that point.

---

## Messaging (Watch ↔ Phone)

- **Watch → Phone:** `startComment`, `endComment{transcript}`, optional
  `play` / `pause` / `seek`.
- **Phone → Watch:** `ack{state}`, `resumed`, errors.
- **Audio clip transfer (if kept):** `WCSession.transferFile` — runs in the background,
  so the loop never blocks on it.

---

## Locked decisions

1. **Comment type** — *Voice clip captured on Watch; phone auto-transcribes via
   `SFSpeechRecognizer` after `transferFile` completes.* No on-Watch dictation modal.
   Transcript stored alongside clip when recognition succeeds; clip remains source of
   truth.
2. **Capture location** — *Watch mic.* Clean, hands-free, no HFP/AirPods-mic concerns.
3. **Trigger** — *Both on-screen button and Double Tap primary action.* Button works on
   every Watch; Double Tap (Series 9 / Ultra 2+) is the no-look path. Same handler.
4. **End behavior** — *Second tap to stop.* Explicit, predictable. No silence detection,
   no hard cap (revisit if runaway clips become a problem).
5. **Resume point** — *Back up ~3 seconds* before resuming. Re-establishes context in
   dense lectures; cost is ~3s of replay per comment.
6. **Storage** — *Local JSON on phone + audio clips on disk* (one annotations JSON per
   lecture, clips in a per-lecture folder). Export as `mm:ss → transcript` CSV later.
7. **Watch wake model** — *Raise-wrist + tap.* No `WKExtendedRuntimeSession`. Watch app
   suspends when screen off; user raises wrist to wake, then taps to mark. Keeps power
   use low and avoids App-Store-hostile background tricks. Implication: trigger latency
   = wrist-raise → app-resume (~1s) before tap registers.

---

## Key APIs (reference)

- **Playback / timeline:** `AVAudioPlayer` or `AVPlayer`, `MPNowPlayingInfoCenter`
- **Recording / dictation:** `AVAudioRecorder`, `SFSpeechRecognizer`
- **Audio session:** `AVAudioSession` (`.playAndRecord`; `bluetoothHighQualityRecording`
  if ever capturing via AirPods)
- **Watch ↔ Phone:** `WatchConnectivity` (`WCSession.sendMessage`, `transferFile`)
- **Watch trigger:** on-screen control, or Double Tap primary action (watchOS 11+)
