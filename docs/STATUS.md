# Android — evidence-based status

This is the independently scoped Android project `metravolokos/aN-cLmL`. The source snapshot and original Git ancestry were imported from `metravolokos/cloudmail-player-m0`. For historical original status, follow the original Git history; current Android requirements are in [ANDROID_SPEC_RU.md](ANDROID_SPEC_RU.md).

## Implemented in source

- Flutter 3.47.9, Dart 3.13.7, Android API 24+, Russian ARB UI.
- Read-only Cloud Mail.ru WebDAV fixed `/AllMusic`, Depth:1 PROPFIND, strict 206 and <=64 KiB Range GET, no redirect with credentials; OS secure storage.
- Drift SQLite catalog, generation refresh, FLAC/MP3 bounded metadata, Cyrillic fallback and album ordering, artwork, cached thumbnails.
- `just_audio`/Android Media3, Android AudioService MediaSession, audio focus, logical track queue, shuffle/repeat, current+next temporary audio cache.
- Android-only app entry point and Android/Quality CI scope. Desktop integration is removed from current active tree during this platform-extraction PR; older implementations remain in Git history.

## Gates before declaring ready

- The Android-only dependency lockfile must be regenerated with pinned Flutter and `flutter pub get --enforce-lockfile` must pass.
- Android Quality and APK builds must pass on exact final HEAD. Preview remains ephemeral debug-signed.
- **No accepted real-device playback result yet** in this destination: Huawei/GMS-free media panel, Bluetooth/USB DAC, live /AllMusic indexing and FLAC/MP3 audio must be tested explicitly.
- Persistent queue/settings, DB migration, very-large-library paging, stable APK signing and recovery need additional work. Unmerged historical PR #36 stale stream-event guards need Android review.

Never infer on-device acceptance from CI, and never modify the original repository as part of this Android development.
