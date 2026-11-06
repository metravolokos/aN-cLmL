# Android build and acceptance

**Only Android is an active target in this repository.** For historical Windows/Linux requirements and build approaches, see original [USER_SPEC_RU.md](USER_SPEC_RU.md) and Git history.

- Flutter 3.47.9, Dart 3.13.7, JDK 17, Android SDK, API 24+.
- Android release runtime graph must not depend on GMS/Firebase. Production manifest must include INTERNET.
- `flutter pub get --enforce-lockfile`, `flutter analyze`, `flutter test`, Python offline tests, and `flutter build apk --debug`.
- Separate Android ARM64 preview workflow validates signature, manifest and no-GMS runtime graph. CI debug-signed release-mode APK is not a production-signed update artifact.
- Physical Huawei test: /AllMusic login, refresh and FLAC/MP3 playback, pause/seek/next, background MediaSession, screen off, BT/LDAC/L2HC where hardware supports, normal audio mixer, USB DAC, call and unplug interruptions; record sanitized artifact hash and observations.
