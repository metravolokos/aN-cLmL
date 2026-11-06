# Android development specification — aN-cLmL
Status: active Android scope, 2026-11-06.

## Provenance and authority

The complete original instruction is preserved verbatim at [USER_SPEC_RU.md](USER_SPEC_RU.md). It specified Windows, Android, and Linux. This document narrows the active scope to **Android only** without rewriting historical user requirements. [REQUIREMENTS_TRACEABILITY.md](REQUIREMENTS_TRACEABILITY.md), [DECISION_INDEX.md](DECISION_INDEX.md), and Git/PR history remain evidence of earlier development, not proof of hardware acceptance.

Priorities: (1) reliable on-device Cloud Mail.ru login/index/playback on Huawei without GMS; (2) production-safe lifecycle, media session, routing and cache; (3) coherent mobile UI and installable APK; (4) distribution hardening.

## Requirements retained

- Flutter and Dart versions pinned by .fvmrc and pubspec.lock. Android minimum SDK 24; no Google Play Services, Firebase, telemetry, or analytics.
- Cloud Mail.ru HTTPS WebDAV at `https://webdav.cloud.mail.ru`, fixed collection `/AllMusic`, no cloud writes. Credentials through on-device OS secure storage only; never leak to source, CI, artifacts or logs. Do not follow redirects with credentials.
- Catalog via local Drift/SQLite; bounded/concurrent FLAC and MP3 indexing, track/album/artist grouping, Cyrillic metadata and filename fallback; recovery from interrupted import. Album/track ordering follows DISCNUMBER/TRACKNUMBER with deterministic fallback.
- Strict HTTP 206 validation. Each upstream Range GET **at most 64 KiB**; verify offsets/content-range and provider dialect. Metadata/cover scans use bounded ranges rather than full-track transfers.
- FLAC cover extraction, bounded persistent album-thumbnail cache; temporary audio cache for current + next only (never unbounded history), network reads continue during pause as designed.
- Android Media3 decode via just_audio, foreground AudioService/MediaSession controls, audio_session music focus, background playback, system audio mixer, seek, pause/resume, next/previous, shuffle/repeat. Opaque MediaSession IDs, no private relative WebDAV paths exposed.
- Russian Material 3 UI through ARB: tracks/albums/artists/settings, compact mini-player, Now Playing, album page, responsive portrait mobile navigation, normalized е/ё search. The accepted Symfonium-inspired patterns are in [UI_SPEC_SYMFONIUM_INSPIRED_RU.md](UI_SPEC_SYMFONIUM_INSPIRED_RU.md).
- Bluetooth and headset behavior, LDAC/L2HC where supported by the OS/device, USB DAC, interruptions, headset unplug and notification/media panel must be checked on real hardware; app must use normal Android output and not claim to select a codec unsupported by system.

## Android acceptance gates

1. Quality CI: formatter, analyze, Flutter/Python tests, layer isolation; Android debug APK build, GMS/Firebase runtime graph audit and manifest permission checks on exact HEAD.
2. ARM64 test-installable APK artifact, signature checked; current ephemeral debug signing is NOT a production upgrade path.
3. Actual Huawei no-GMS test: sign in with app password entered locally; list and index /AllMusic, observe progress, metadata and album art, play FLAC/MP3 audibly, seek, switch tracks, pause, resume and stop without stale playback.
4. Exercise background screen-off playback, Android media panel/media keys, audio focus, calls, unplug, phone speaker/BT/USB DAC with system mixer. OEM lock-screen limitations are reported separately, not silently considered implemented.
5. Record device model, OS/version, artifact SHA and sanitized result for each test. No private filenames, credentials or authorization headers in evidence.

## Excluded from current work

Windows SMTC, desktop libmpv, Linux MPRIS/Wayland/Flatpak, Windows installers, desktop adaptive layout. These remain in original Git history and original specification, but **must not drive new Android tasks or block Android PRs**.

## Known unfinished items

Hardware/live-cloud acceptance is incomplete; stable APK signing and update path are incomplete. Catalog scaling/migration and crash recovery still need targeted evidence. Historical upstream PR #36 proposes stale stream-event guards; evaluate and test on Android before adopting. Upstream PR #48 has an unmerged explainability contract. Do not claim those fixes merged into Android.

## Agent conduct

Inspect HEAD, open PRs, current code and CI before changes. Do not reimplement completed functionality, merge draft PRs, weaken secret/range limits, invent test outcomes or conflate CI with real-device acceptance. Every nontrivial change needs a rationale, regression gate and updated history/decision links. Use one focused PR at a time, review exact HEAD and preserve Git ancestry.
