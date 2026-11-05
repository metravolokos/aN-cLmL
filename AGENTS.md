# CloudMail Player — coding rules for all agents

Read docs/STATUS.md, docs/SPEC.md, docs/ROADMAP.md and docs/TECH_STACK.md at the beginning of each task.

## Goal
One Flutter codebase for Windows 10/11, Android without Google services and
Linux x86_64 GNOME 51 Wayland. User communication Russian. Source, tests,
docs, ADR and commits English. Russian UI strings in lib/l10n/*.arb.

## Non-negotiable rules
- No credentials or personal filenames in sources, tests, commits, PRs or CI.
- Cloud source only HTTPS Cloud Mail.ru /AllMusic. No remote writes. Never follow
  redirects with Basic Authorization.
- No GMS, Play Services, Firebase, analytics, telemetry, playlists, favorites or EQ.
- Architecture chooses domain abstractions first. Platform-specific imports and
  runtime platform checks only in lib/platform, NOT lib/domain or data and UI.
- Use pinned dependencies and the actual pubspec.lock. No guessing versions.
- One focused change, its tests, analyzer, 3 platform builds where possible,
  dated STATUS and ADR. Do not suppress broken tests or run long endurance tests.
- No remote audio full-file GET for metadata; use bounded 206 Range chunks.
- Android Internet permission must exist in the RELEASE merged manifest.
- Do not make claims of GNOME 51, actual sound, MPRIS, or secret-store runtime
  acceptance without on-device verification.

## Current development status
This branch tests a short vertical slice: cloud listing and seekable audio
source. It is not a final accepted player. Refer to docs/STATUS.md for the
list of unfinished requirements. Only main receives approved, reviewed PRs.

## CI
Flutter 3.47.9 via .fvmrc, Dart formatter, flutter gen-l10n, flutter analyze,
flutter test, M0 Python tests, tools/check_layers.sh, Android/GMS audit,
Windows release build and Linux release build. No secrets in CI.
