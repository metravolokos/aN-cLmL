# CloudMail Player — implementation status (2026-11-06)

## Integrated on main (source and CI, not hardware acceptance)

- Flutter 3.47.9 one-codebase app with Russian Material 3 interface and Android, Windows, Linux build runners.
- Authenticated, read-only Cloud Mail.ru WebDAV rooted at `/AllMusic`, secure OS credential store, bounded PROPFIND, HTTP 206 Range GET and 64 KiB network GET cap.
- Drift/SQLite catalog, FLAC/MP3 metadata indexing, tracks/albums/artists, search and album track/disc ordering (PR #21).
- just_audio (Android Media3) and MediaKit (Windows/Linux) playback, queue, shuffle/repeat, mini-player, Now Playing and temporary current+next cache.
- Async Stop/track-switch and credential/Disconnect generation guards; late Play/Seek cannot restart a stopped queue (PR #23).
- Embedded FLAC artwork, lazy album thumbnails and responsive album grid with playable disc/track-ordered album sheet (PRs #15, #18, #24).
- Android foreground MediaSession and system/headset buttons (PR #19); Windows SMTC controls (PR #22); Linux MPRIS D-Bus bridge (PR #25). Platform adapters use the same playback controller and OS audio mixer.

## In development

- Android music audio focus configuration (separate feature branch and CI). Hardware interruptions and headset routing unverified.
- Persistent resized artwork thumbnail cache with bounded disk LRU; current cover cache is a small in-memory cache only.
- Signed/distributable APK, Windows package and Linux Flatpak.

## NOT yet validated on physical devices / real cloud

- Authenticated `/AllMusic` indexing and FLAC/MP3 playback on all three target platforms, including seek and cache reuse, without full-file metadata downloads.
- Android AOSP without GMS and Huawei device media panel, Bluetooth, USB DAC, headphone disconnect, phone call interruption and real background playback.
- Windows 11 SMTC media keys and sound on actual hardware.
- GNOME 51 Wayland Linux launch, MPRIS media controls, Secret Service persistence and Flatpak sandbox behavior.
- Application startup from distributable signed/packaged artifacts.
- Large-library UX/performance; gapless playback is not claimed.

## Process

Quality + Android + Windows + Linux jobs must all be green for the exact current PR head, with conflict check, before merge. CI builds validate source and artifacts, **never** actual audio, OS media panels or real Cloud Mail.ru server behavior. No credentials in code, logs or CI, and no modifications to remote music files. Run only targeted tests with a meaningful failure or acceptance gate.

## Recent merged PRs

- #15 and #18 — embedded FLAC cover and album thumbnails.
- #19 — Android foreground MediaSession.
- #21 — album disc/track ordering.
- #22 — Windows native SMTC.
- #23 — stale media-command protection after Stop.
- #24 — responsive album cover grid.
- #25 — Linux MPRIS.
