# CloudMail Player

Flutter application shell for Windows and Android, with a Russian Material 3 UI.
The M1 implementation includes Tracks, Albums, Artists and Settings destinations,
responsive bottom/rail navigation, and system/light/dark theme selection. Theme
and navigation state are in memory; restarting resets them to system/tracks.

**M1 validation is blocked; this is not a verified working player or a completed
milestone.** No cloud connection, library index or audio playback is implemented.
No credentials are requested. M2 has not started.

## Development

Target SDK source: Flutter stable 3.47.9, revision
`c197ca5199e9ee5661e865596c9c07294dfab51c`. See
[the stack decision](docs/adr/0001-stack.md) for provenance and limitations.
Install Flutter from its official distribution and add `flutter/bin` to PATH.

```sh
flutter --version
dart --version
flutter pub get
flutter gen-l10n
dart format lib test
flutter analyze
flutter test
flutter run -d windows  # Windows host with Visual Studio C++ toolchain
flutter devices        # Find the Android device ID
flutter run -d DEVICE_ID
```

`pubspec.lock` is not yet available: dependency resolution requires a working
Flutter/Dart installation. Generate and commit it before completing M1; subsequent
local and CI resolution must use `flutter pub get --enforce-lockfile`.

```sh
flutter build apk --debug    # JDK and Android SDK required
flutter build windows --release # Windows + Visual Studio C++ required
python -m unittest discover -s tests -v
```

CI defines separate quality, Android debug APK and Windows release build jobs.
A workflow definition is not build evidence. Current failures and exact attempted
commands are recorded in [STATUS](docs/STATUS.md).

## Structure

- `lib/app`: Riverpod app state, app entry widget, responsive shell and settings.
- `lib/l10n/app_ru.arb`: all application UI messages; `flutter gen-l10n` creates
  ignored Dart localizations next to the ARB file.
- `lib/domain/services.dart`: future cloud/storage/player contracts only.
- `android`, `windows`: native runners; Android minimum API 24.
- `test`: focused Flutter widget tests; `tests` and `tools`: retained M0 Python probe.

## Scope and privacy

Future source: Cloud Mail.ru WebDAV `/AllMusic` only. No GMS, Firebase, analytics,
playlists or favorites. Android Gradle's build-time `google()` repository is for
Android build tooling; the application declares no Google services dependency.
Do not run the live M0 probe as part of M1. Do not use account credentials or
modify cloud data. See [AGENTS](AGENTS.md), [SPEC](docs/SPEC.md),
[ROADMAP](docs/ROADMAP.md) and [M0 notes](docs/webdav-notes.md).
