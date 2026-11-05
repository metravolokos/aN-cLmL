# CloudMail Player

A Flutter app for Windows and Android, initially using Russian Material 3 UI.
**M1 app shell has been accepted**: tracks, albums, artists and settings screens,
adaptive bottom navigation / Windows rail, and system/light/dark theme mode.
The user confirmed launches and UI operation on both platforms (2026-11-05).

**M2-A connection slice:** Settings accepts a Cloud Mail.ru login and an
external-application password, verifies read-only access to `/AllMusic`, and
stores both values in OS-backed secure storage. The WebDAV client only issues
Depth 0/1 PROPFIND and bounded Range GET requests to
`https://webdav.cloud.mail.ru/AllMusic` and descendants. It does not build a
catalog, read tags, download complete media files, or play audio.

**Not yet implemented:** local music indexing, artwork, playback, queues or
background services. M2-B and M2-C remain separate slices.

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
- lib/cloud: bounded read-only WebDAV transport and secure credential service.
- lib/domain/services.dart: contracts for later catalog and playback work.
- android, windows: native runners; Android minimum API 24.
- test: Flutter widgets; tests and tools: bounded Python M0 probe.
- docs: status, roadmap, architecture decisions and focused M2-A task.

## Privacy and connection behavior

Cloud requests are restricted to `https://webdav.cloud.mail.ru/AllMusic` and
descendants; redirects are disabled. Login and app password are written to
OS-backed secure storage only after a successful check. Android app backups are
disabled so encrypted keys cannot be restored without their device keystore.
Disconnect deletes both stored values. CI uses only a local anonymous fake
server and never receives a personal Cloud Mail.ru credential.

The Android build checks its resolved runtime dependency graph for Google Play
Services and Firebase. The secure-storage plugin's Android cryptography
dependency is Tink, a standalone crypto library, not Google Play Services.
There is no telemetry, playlist, favorite, or GMS dependency.

Next scope: M2-B local SQLite catalog as a separate change, tracked in
[Issue #3](https://github.com/metravolokos/cloudmail-player-m0/issues/3).
