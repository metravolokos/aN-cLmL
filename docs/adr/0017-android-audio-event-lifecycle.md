# ADR 0017 — Android audio event lifecycle gate

Date: 2026-11-06
Status: proposed (pending CI and physical device playback)

## Context

The imported PlaybackController kept a single just_audio AudioPlayer while replacing source tracks. It already ignored playing/error events during `_changingTrack`, but position, duration and processing events could overwrite the new track's initial view. Delayed events could also arrive after Stop, when the queue has been cleared. The original unmerged [PR #36](https://github.com/metravolokos/cloudmail-player-m0/pull/36) documented the first half of this defect.

## Choice

Apply one small, side-effect-free lifecycle predicate to all five event subscriptions: position, duration, playing, processing and error. Events can update view state only when controller is not disposed, no source switch is underway, an active queue exists, and a current track is selected. Only accepted completed-state events may auto-advance.

This keeps existing playback generation guards, WebDAV transport and audio backend unchanged. Regression tests exercise gate states and confirm every stream handler uses the common gate. The resulting source-level tests do **not** simulate actual asynchronous Media3 callbacks.

## Known limitation

Events emitted after `setAudioSource` completes but originating from an earlier source cannot always be attributed to the correct generation with a shared AudioPlayer stream. Do not claim complete stale-event elimination or hardware acceptance from this narrow change. Validate fast next/previous/stop, media keys and background AudioService on physical Huawei. A subsequent change may need deeper source-generation tagging if a reproducible defect remains.
