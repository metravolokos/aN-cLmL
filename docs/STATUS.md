# Project status — 2026-11-05

## M0 — accepted bounded WebDAV connectivity

Authenticated read-only Codex Cloud probe confirmed /AllMusic through PROPFIND (207), sampled HEAD (200) and five bounded Range GETs (206). The provider returned Content-Range in bytes=first-last/total form. Six offline Python tests passed. This does not establish full indexing or audio playback. Details in docs/webdav-notes.md.

## M1 — accepted Android and Windows Flutter UI scaffold

User confirmed on 2026-11-05 that the application **launches and works on both target platforms**. This is manual acceptance of the existing UI shell, not of WebDAV or audio playback.

M1 includes Russian ARB localization, Material 3, responsive four-destination navigation (Tracks, Albums, Artists, Settings), theme selection and honest disconnected states. No personal WebDAV secrets or data are included.

Confirmed in GitHub Actions run #42013267771:
- Quality: Flutter 3.47.9, Dart 3.13.7; generated localizations, strict formatting, flutter analyze without issues; four Flutter widget tests and six Python M0 tests passed.
- Android: flutter build apk --debug succeeded; artifact cloudmail-player-android-debug.
- Windows: flutter build windows --release succeeded; artifact cloudmail-player-windows.
- The user launched both applications and reported they work.

Finalization: Flutter's official generator was run on the Android/Windows platform projects; a real pubspec.lock was generated and committed, with any generated Windows registrant adjustments. Reproduction is enforced through flutter pub get --enforce-lockfile. The one-off finalization workflow has been removed.

A formal GMS-dependency audit has not yet been performed on the APK and remains a release criterion. No playback, personal cloud integration or full index is implemented at M1.

M1 Draft PR #2 is accepted and authorized for merge into main; the user approved advancing to M2. The next work starts from the merged main; do not continue stale Codex work checkouts.

## M2-A — secure connection slice

Implemented on `feature/m2-a-secure-webdav`; Draft PR and current CI evidence are
recorded after the platform workflows complete. The Settings UI accepts a
Cloud Mail.ru login and external-application password, checks `/AllMusic` with
Depth 0 PROPFIND, reports Russian errors, stores credentials only after a
successful response, and removes them on Disconnect. A blank password reuses
the OS-stored value for the same login without displaying it.

The read-only client supports Depth 0/1 PROPFIND and exact 206 byte ranges up to
128 KiB. It rejects responses outside `/AllMusic`, cross-origin redirects,
traversal hrefs, malformed XML, oversized bodies, unexpected status codes and
bad Content-Range framing. Network calls have an 8-second timeout, cancellation
and at most one bounded retry. No full scan, SQLite catalog, tags, whole-file
download, or playback is implemented.

Dependencies: Dio 5.11.1, `xml` 7.1.0, and `flutter_secure_storage` 11.2.0;
decision and platform evidence are in `docs/adr/0002-webdav-transport-and-secrets.md`.
CI uses local fake WebDAV fixtures only. No Cloud Mail.ru credentials are used
in GitHub Actions. Manual connection and secure-storage checks on the user's
Android and Windows devices remain required before M2-B.

## M2 — next, focused scope

Issue #3: https://github.com/metravolokos/cloudmail-player-m0/issues/3

After M2-A user acceptance, proceed with the incremental SQLite catalog in
M2-B and ranged tag extraction in M2-C as separate slices. Do not build full
playback or run multi-hour stress tests.

## Security / constraints

Cloud source restricted to /AllMusic. No GMS, telemetry, playlists, favorites or equalizer. Never commit credentials, accounts or private filenames. M0 temporary app password was exposed earlier in chat; rotate before any new live testing.
