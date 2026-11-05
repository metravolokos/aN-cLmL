# CloudMail Player

A Flutter app for Windows and Android, initially using Russian Material 3 UI.
**M1 app shell has been accepted**: tracks, albums, artists and settings screens,
adaptive bottom navigation / Windows rail, and system/light/dark theme mode.
The user confirmed launches and UI operation on both platforms (2026-11-05).

**Not yet implemented:** actual connection to Cloud Mail.ru, music indexing,
artwork, playback, queues or background services. M2-A is the next step.

## Development

Flutter 3.47.9 stable (revision c197ca5199), Dart 3.13.7, Windows or Android toolchain.
Dependencies are reproducibly pinned by the committed pubspec.lock.

~~~sh
flutter --version
dart --version
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
python -m unittest discover -s tests -v
flutter build apk --debug        # Android SDK/JDK
flutter build windows --release # On Windows with Visual Studio C++ build tools
~~~

CI separates Linux Quality, Android APK, Windows release build; the first full
green run was https://github.com/metravolokos/cloudmail-player-m0/actions/runs/42013267771.
The M1 finalization job subsequently generated the genuine lockfile and
reconciled official platform templates. Device UI smoke tests were confirmed by
the user. The GMS-free binary audit remains a release acceptance check.

## Layout

- lib/app: Material UI shell and Riverpod navigation/theme state.
- lib/l10n/app_ru.arb: Russian strings, gen-l10n generated Dart classes.
- lib/domain/services.dart: contracts, not connected implementations.
- android, windows: native runners; Android minimum API 24.
- test: Flutter widgets; tests and tools: bounded Python M0 probe.
- docs: status, roadmap, architecture decisions and focused M2-A task.

## Privacy

Future cloud source is strictly https://webdav.cloud.mail.ru/AllMusic. Do not
commit secrets or personal cloud filenames. No GMS, Firebase, telemetry,
playlists or favorites. Android build-time Google's Maven repository does not
imply runtime Google Mobile Services, but the final APK still needs auditing.

Next scope: docs/M2A_CODEX_TASK.md; comprehensive M2 plan in Issue #3.
