# ADR: Ignore stale player stream updates while switching tracks

Date: 2026-11-06

## Context

`setAudioSource` emits position, duration, playing, processing and error events asynchronously. While the UI already shows the newly selected track, callbacks may still describe the previous source.

## Decision

Suppress updates from these player streams while `_changingTrack` is true. Source replacement remains responsible for setting the new loading state; after it finishes, normal stream updates resume. No new dependency or remote write is introduced.

## Limitations

This is a source-level race guard, not proof of playback on physical devices. The follow-up gate is exact-head Quality, Android, Windows and Linux CI plus targeted asynchronous playback regression coverage before merging.
