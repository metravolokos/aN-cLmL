# M2-A — real Cloud Mail.ru connection on Windows and Android

Status: approved to start after the user accepted M1 on both platforms, and PR #2 was merged as 288db54d7acf6912a2036878c468d4c3cf505ba9.

Read AGENTS.md, docs/SPEC.md, docs/STATUS.md, docs/webdav-notes.md and Issue #3 first. Work **only on feature/m2a-cloud-connection** and submit a Draft PR against main. Do not merge or begin M2-B automatically.

## Objective
A user can enter their Cloud Mail.ru WebDAV app credentials in the Russian Settings screen, tap Connect, and see a truthful Connected/Failed state after a read-only request to /AllMusic. The app works on both Windows and Android without Google services. Disconnect clears session credentials and stored credentials when the user chooses Disconnect. No library indexing or playback yet.

## Implementation guidance
- Review pub.dev compatibility with the committed Flutter/Dart SDK and lockfile before selecting dependencies. Current candidates as of 2026-11-05: dio 5.11.1 (cancellation/timeouts; supports Windows+Android) and flutter_secure_storage 11.2.0 (Windows+Android). Use only what is necessary; document any alternative choice and platform security properties in one short ADR. The Windows backend and Android Keystore behavior must be evaluated, not merely assumed.
- Never check a username, app password, encoded Authorization header, raw private XML or private filenames into public git, test fixtures, screenshot, log, CI, crash analytics or PR.
- Use the fixed endpoint https://webdav.cloud.mail.ru and restrict all WebDAV resource paths to /AllMusic and its descendants; reject path escapes in decoded Unicode and percent-encoded paths.
- Write the read-only WebDAV PROPFIND Depth:0 request in a small client/service separate from widgets, with HTTPS, timeouts, cancellation and a correctly scoped Basic auth header. Verify returned 207 and actual /AllMusic collection; distinguish 401/403, 404, malformed XML, timeout and other network errors. Never treat HTTP 200 alone as proof of connection.
- No external account requests in CI. Supply a fake HTTP transport/server covering 207, 401, 404, malformed XML, path escape, cancellation and no-secret logging; add focused widgets tests for Settings Connect/Disconnect and errors. Keep tests short.
- Android internet permission and platform manifest checks as needed; maintain minSdk 24. No GMS or Firebase.
- Save credentials in OS-backed secret storage only after successful authenticated check; provide explicit handling for unreadable/corrupt saved credentials and Disconnect. Do not log secrets. Never save as plain SharedPreferences, SQLite or Dart logs.
- Verify with flutter pub get, gen-l10n, format, analyze, test, Android APK and Windows release builds via CI. Update pubspec.lock and short docs; do not claim manual connection or testing until user confirms on devices.

## Output
Draft PR URL, head SHA, concise checklist of tested behaviors, three CI results, and a request for a single real-user Connect/Disconnect smoke test after APK/Windows artifacts are available.

## Explicit non-goals
No PROPFIND Depth:1 recursive scan beyond what is strictly needed to confirm the target collection, no library storage, database, metadata extraction, artwork, audio, UI redesign, stress tests, repeated M0 probe, or long end-to-end tests. M2-B and M2-C are separate PRs.
