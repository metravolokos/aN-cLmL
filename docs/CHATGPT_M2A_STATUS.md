# ChatGPT independent M2-A experiment — 2026-11-05

This is an independent comparison with Codex Cloud, not an accepted or merged
implementation. Branch: experiment/chatgpt-m2a, base main
288db54d7acf6912a2036878c468d4c3cf505ba9. M1 was previously accepted:
CI #42022705598 had Quality, Windows and Android green; the user confirmed
the app launches on both platforms.

## M2-A scope in this branch

- Production read-only HTTP/WebDAV client restricted to Cloud Mail.ru /AllMusic.
- Namespaced DAV: 207 parser, safe path containment, no external redirects.
- GET with strictly bounded Range and observed Content-Range bytes= support.
- OS encrypted vault for login and app password, connection Settings UI, clear
  error messages, cancellation and disconnect.
- Fake local WebDAV integration tests with synthetic data; no account secrets.

## Validation status

The ChatGPT execution container has no Flutter/Dart SDK and cannot reach
github.com directly. Source written with GitHub connector; actual format,
analyze, test and Windows/Android builds must be confirmed by GitHub Actions.
Do not claim success until jobs complete. The app password previously exposed
must be rotated before live manual sign-in testing.

## Not included

No SQLite index, music file traversal, metadata parsing, artwork, playback or
background service. Stop after Draft PR and comparison.
