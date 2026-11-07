# ADR-0023: Standard integrated buffered seek slider on Android

Date: 2026-11-07. Status: proposed, pending CI and physical device acceptance.

## Context
The separate 12 dp decorative buffered strip from ADR-0021 was drawn under a visually transparent Flutter Slider with manual horizontal insets. It did not look or behave like a normal unified playback timeline. The user explicitly rejected this presentation and requested a conventional wide filled bar with a thumb, darker downloaded region, and a distinct played trail.

## Decision
- On Now Playing use one native Material Slider, with a 10 dp rounded track and a small round thumb aligned to the same track's geometry. No custom stacked canvas or invisible overlaid slider.
- Use the slider's active track for heard audio, secondaryTrackValue and secondaryActiveTrackColor for contiguous cache download progress, and inactive track for the unbuffered remainder. This reflects cached file bytes, not an exact decoder buffer or indexing metadata.
- Keep elapsed/total time labels and retain the user's ability to scrub. onChanged updates only a local preview; onChangeEnd commits exactly one playback seek.
- Disable seeking if the duration is not yet known; clamp both timeline and cache values to the seek range. Do not introduce extra WebDAV requests, change the cache policy, or alter mini-player progress.

## Evidence and validation
- The previously accepted waveform and the later custom linear strip were rejected for their visual presentation during the on-device Huawei review.
- Widget tests must assert native secondary buffer progress, played position, normal rounded track geometry, seek-on-release behavior, and a disabled slider for unknown duration.
- Require green CI and visual/device testing before merge. This is a UI change, not evidence of actual hardware acceptance.
