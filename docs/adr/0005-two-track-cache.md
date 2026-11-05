# ADR 0005: Bounded two-track temporary audio cache

Date: 2026-11-05
Status: Implemented on isolated branch; hardware and real-cloud acceptance pending

## Context

The first player slice downloaded a network Range on every seek. The requirements
specify temporary caching of only the current and next track; downloading while
paused, full current preload before next preload, instant cached seeks, no history,
hard disk quota, and startup cleanup.

## Decision

Use a read-through TwoTrackAudioCache in lib/data/audio, independent of Dio,
Media3 and libmpv, with an injected RemoteRangeReader. Requested audio is fetched
in 64 KiB pages. Unaligned seeks may require two upstream Range calls. Validated
blocks are stored at their original offsets in a temporary .part file; when the
entire file is present it is atomically renamed to .cache.

At most the selected current and next tracks have cache entries. SHA-256
identifiers combine path, ETag and size; original personal names are not
stored in filenames. Queue changes delete history and preserve warmed next
data when it becomes current. The default 256 MiB hard cap counts declared
track sizes, not only fetched bytes, including sparse seeks. If a track cannot
fit it streams directly, never violating the quota.

Sequential background prefetch fills current before next; Pause does not stop
it, while a queue change cancels additional read-ahead using a generation
counter. If temporary storage fails, the controller streams directly. Startup
cleans orphaned partial/completed cache files. No permanent cache survives
restarting the app.

## Alternatives

- just_audio LockCachingAudioSource: potentially simpler but must be validated
  on Media3 and media_kit, particularly seek and Authorization.
- Whole-track download before play: delays the first sound.
- Memory LRU: risks large FLAC RAM consumption.
- Page-per-file LRU: many disk files and less straightforward full-track reuse.

## Evidence and limitations

The unit suite covers bounded and repeated seek, no-network cache hit,
two-track eviction, prefetch ordering, incorrect upstream length, orphan
cleanup and concurrent request coalescing. These offline tests do not prove
real audio playback on the Huawei, Windows or GNOME Wayland. Build and
on-device verification are separate required gates.
