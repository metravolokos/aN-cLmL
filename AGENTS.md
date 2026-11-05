# CloudMail Player — instructions for coding agents

Read docs/STATUS.md, docs/ROADMAP.md, docs/SPEC.md and the active task before editing. The user approved M1 merge and M2 development on 2026-11-05.

## Communication and security
- Communicate with the user in Russian. Code, ADRs, documentation and commit messages in English. App UI starts in Russian through ARB.
- Never commit, log, expose, screenshot or print credentials, email addresses, private cloud filenames, Authorization headers or raw WebDAV XML.
- Never put personal credentials in CI. For optional live manual tests, use the user-controlled secret store; previously exposed temporary passwords must be rotated.
- The only music source is Cloud Mail.ru WebDAV at /AllMusic. Protect path containment, bound Range responses, and respect cancellations.
- No GMS, Firebase, telemetry, analytics, Google-dependent runtime, playlists, favorites, equalizer, lyrics or ALAC.
- Do not modify or delete files in the cloud.

## Current state and scope
- M0: accepted bounded real WebDAV observation; see docs/webdav-notes.md.
- M1: accepted Windows and Android Flutter shell; generated pubspec.lock, verified build, real user smoke test. See docs/STATUS.md.
- Next: **M2-A only** under docs/M2A_CODEX_TASK.md and Issue #3. Build a real secure connection and bounded read-only WebDAV client with a Russian connection UI.
- SQLite index, tagged metadata scans, covers and playback must wait for subsequent M2-B/C/M3/M4 slices. Do not build everything at once.

## Engineering workflow
- Start from current origin/main, not stale Codex checkout. Work on a feature branch in small steps and submit a Draft PR; no unapproved merges.
- Verify actual package and platform compatibility before choosing dependencies; pin versions in pubspec.yaml and a real pubspec.lock. Do not invent versions.
- CI uses flutter pub get --enforce-lockfile; run formatter, analyzer, focused widget/integration tests and real Android/Windows builds where available. Distinguish a compiled app from a tested running app.
- Do not suppress failures, remove useful tests or run multi-hour tests without specific need and user approval.
- Update docs/STATUS.md, docs/ROADMAP.md, and an ADR for nontrivial decisions with changes in behavior.
