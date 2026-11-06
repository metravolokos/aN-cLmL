# ADR 0018 — Cache-backed buffered waveform on Android Now Playing

Date: 2026-11-06
Status: proposed pending CI and physical device acceptance

## Context

A separate indeterminate LinearProgressIndicator appeared above the seek slider while a track was loading. It occupied vertical space and did not communicate how much of the audio was actually present in the current-track cache. The accepted Android UX calls for one integrated, Symfonium-inspired visualization of played, downloaded and not-yet-buffered regions.

## Decision

- Use existing TwoTrackAudioCache contiguous downloaded-byte counter divided by current file size for `PlaybackView.bufferedFraction`. Report only on percent changes, and scope callbacks to the active slot and playback generation.
- Draw a non-audio-derived, deterministic, stylized waveform motif using Flutter CustomPainter. Distinguish played, downloaded, and unloaded segments with color/opacity.
- Overlay the existing Slider as the interactive seek control, preserving seek-on-release and accessibility. Remove the detached loading progress bar on Now Playing.
- Keep the cache restriction (current + next, 512 MiB), read-only WebDAV protocol and <=64 KiB Range boundary unchanged.

## Limitations

This is a **cache download indicator**, not an exact decoder playback buffer map. If caching is unavailable, a stream can still play directly over WebDAV while the cache meter stays at zero. The visual bars are stylized decoration, not measured frequency/amplitude samples. Do not display private file paths, byte counts or credentials. Physical Huawei acceptance and accessibility contrast remain separate gates.
