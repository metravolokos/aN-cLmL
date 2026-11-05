# CloudMail Player — implementation status (2026-11-05)

## What is integrated on main

- Flutter 3.47.9 single-codebase application with Android, Windows and Linux runners and Russian Material 3 interface.
- Authenticated, read-only Cloud Mail.ru WebDAV rooted at `/AllMusic`, with secure OS credential storage, bounded PROPFIND and validated HTTP 206 Range GETs.
- Hard network limit: **64 KiB per Range GET** at the transport boundary (PR #14).
- Drift/SQLite account-scoped catalog, generation scans, FLAC/MP3 bounded metadata extraction, tracks/albums/artists views and search.
- Native playback through just_audio on Android and media_kit-based Windows/Linux integration, seekable Cloud Range stream, queue, shuffle/repeat, mini-player and Now Playing.
- Temporary two-track audio cache, current-first read-ahead and next-track prefetch, including cleanup on Stop.
- Stop/track-switch generation guard with last-selection-wins behavior (PR #12).
- Session invalidation during account change and Disconnect, including delayed secure-vault-read protection (PR #13).

## Source implementation is not hardware acceptance

GitHub Quality/Android/Windows/Linux CI can validate source, unit tests and build binaries but does not prove audible playback, Bluetooth/media panel behavior, secure-store access on a real phone, or GNOME 51/Wayland integration.

## Not finished / not accepted

- Real authenticated Cloud Mail.ru catalog and playback acceptance on all three target platforms.
- Android foreground MediaSession, notification/media panel, audio focus and Bluetooth behavior.
- Windows SMTC and media keys; Linux MPRIS, GNOME 51 Wayland and Flatpak operation.
- Album cover grid, persistent thumbnail cache and image resizing; FLAC cover parsing and Now Playing integration remain in separate PR #15 pending CI.
- Signed/distributable release artifacts (APK, Windows ZIP/installer and Flatpak), performance acceptance and complete 50k library testing.
- No claim of gapless or uninterrupted track switching on actual devices.

## Working process

Require green Quality + Android + Windows + Linux CI before merging source changes. Record device and real-cloud manual acceptance separately from automated tests. No credentials in code, GitHub issues, logs or CI artifacts. Keep tests purposeful; avoid stress suites without a specific defect or acceptance criterion.

## Reference pull requests

- PR #11: consolidated three-platform development preview.
- PR #12: Stop and rapid track-switch race fix (merged).
- PR #13: credential-read/Disconnect race fix (merged).
- PR #14: 64 KiB WebDAV transport limit (merged).
- PR #15: lazy FLAC embedded artwork and Now Playing integration (under review).
