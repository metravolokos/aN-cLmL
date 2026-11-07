# teStPlaYclouDE — Android

This is the **independent Android continuation** of the original three-platform Cloud Mail.ru WebDAV player, which was developed in [cloudmail-player-m0](https://github.com/metravolokos/cloudmail-player-m0). The complete original Git ancestry and experimental refs were imported; earlier platform code remains available in Git history, **not** the current Android source tree.

> Development preview only. CI compiles and tests source; real Huawei/GMS-free cloud login, audio playback, Bluetooth/USB DAC and media-panel acceptance must be reported separately. Do not treat an APK build as a hardware test.

## Android implementation

Flutter 3.47.9 / Dart 3.13.7 (see `.fvmrc`), Android API 24+, no Google Play Services. Russian Material 3 UI and ARB, read-only HTTPS WebDAV at `https://webdav.cloud.mail.ru/AllMusic`; bounded 64 KiB HTTP Range GET with strict 206 checks; Drift/SQLite catalog; incremental FLAC/MP3 metadata; album artwork; persistent bounded thumbnail cache; current+next temporary audio cache; Android just_audio/Media3, foreground AudioService MediaSession, audio focus and OS mixer.

Install Flutter SDK + Android SDK / JDK 17, then:

```bash
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter analyze
flutter test
python -m unittest discover -s tests -v
flutter build apk --debug
```

A single standard Android APK, `app-debug.apk`, is built by the [Android and quality workflow](https://github.com/metravolokos/aN-cLmL/actions/workflows/flutter.yml) and published as the `an-clml-android-debug` artifact. There is no separate CPU- or vendor-specific build. The test APK uses debug signing, not a stable production/update signature. See [installation instructions](docs/ANDROID_PREVIEW.md). Account credentials must be entered only on-device; never provide them via CI/issues.

## Sources of truth

- [Current Android specification](docs/ANDROID_SPEC_RU.md) and [agent instructions](AGENTS.md).
- [Current status](docs/STATUS.md) and [Android roadmap](docs/ROADMAP.md).
- [Original Russian specification](docs/USER_SPEC_RU.md): immutable historical source covering Android, Windows and Linux.
- [History](docs/DEVELOPMENT_HISTORY.md), [architecture decisions](docs/DECISION_INDEX.md), [original Git refs](https://github.com/metravolokos/aN-cLmL/branches).
- Historical PR/issue indexes are being incorporated in separate [PR #3](https://github.com/metravolokos/aN-cLmL/pull/3).

The owner has not authorized a project-wide source licence. Third-party packages and native codec distribution remain subject to their own licence review. No playlists/favorites/telemetry and no cloud writes.
