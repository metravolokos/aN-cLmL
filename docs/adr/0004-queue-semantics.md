# ADR 0004: Playback queue semantics

Date: 2026-11-05
Status: Implemented on a review branch; device audio verification pending.

## Context

The first three-platform vertical slice could play only a single file and had no queue context, next/previous, shuffle or repeat. The product requires navigation for track, album and artist selections while leaving network and decoder implementation independent of queue ordering.

## Decision

Use a small, pure-Dart TrackQueue in lib/domain. Its original order is immutable during one playback context. An explicit source index selects the first track; shuffle uses Fisher-Yates on remaining indices while retaining the current item. Disabling shuffle restores source order at the same original item.

Repeat modes: Off (do not wrap), All (wrap), One (automatic end-of-track returns current; manually pressing Next/Previous navigates). The queue exposes null at boundaries. PlaybackController is the only integration layer to just_audio, and a tap on Tracks/Album/Artist sets a queue from the selected context. No cloud or disk access occurs inside TrackQueue.

## Consequences

The module is independent of Flutter, Media3, libmpv and WebDAV and has deterministic randomized tests. This first implementation invokes a new audio source at each transition; gapless, current/next caching and persistence are deferred to later milestones. End-of-track transitions use the audio processing-state callback, and platform/audio behavior still requires real-device validation. The mini-player controls are in Russian. No claim of seamless playback is made.
