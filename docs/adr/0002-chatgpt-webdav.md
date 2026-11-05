# ADR 0002 (ChatGPT experiment): M2-A Cloud Mail.ru transport and secrets

Date: 2026-11-05
Status: Experimental / Draft PR; device validation pending.

## Comparison isolation

This implementation is intentionally separate from the Codex agent's work.
It starts at the same M1 main commit (288db54d7acf6912a2036878c468d4c3cf505ba9)
on branch experiment/chatgpt-m2a. Do not cherry-pick the other experiment into
this one before comparing test results and runtime behavior.

## Decision

- Read-only WebDAV: dart:io HttpClient (bundled with Flutter, no HTTP plugin).
  Production origin/root is fixed to https://webdav.cloud.mail.ru/AllMusic/.
  One factory accepts only 127.0.0.1 for fake-server integration tests.
- XML: xml 7.1.0 (Dart 3.13). Validate DAV: namespace, XML multistatus and
  the required root collection, reject out-of-root/cross-origin hrefs.
- Credentials: flutter_secure_storage 11.2.0, default Android Keystore
  RSA-OAEP/AES-GCM and Windows OS protected encryption. Windows build may
  require ATL component in Visual Studio. This is not Google Play Services.
- UI: one Settings screen with login, masked app password, connect/cancel/
  disconnect and localized errors, no plaintext storage, logs or CI credentials.
- Strict HTTP: PROPFIND depth 0/1, limited XML response; GET Range <=128KiB
  and validation of 206, body length, start/end/total; accommodate Cloud Mail.ru's
  observed Content-Range bytes= form as well as RFC bytes space. Block redirects.
- Client requests bounded with short timeout and a cancellation token.
  M2-A does not create any library index, scan, artwork or player.

## Remaining validation

Flutter/Windows and Android builds must succeed with real pubspec.lock. Run
fake-server tests; test actual sign-in/disconnect on both devices after the user
rotates the exposed temporary password. No live WebDAV testing with secrets in CI.
The Windows/plugin binary needs an actual runtime check; compilation alone is
not proof that OS secure storage works. Review privacy and GMS-free properties
of the final APK before release.
