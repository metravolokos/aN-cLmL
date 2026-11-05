# CloudMail Player — instructions for coding agents

Read docs/STATUS.md, docs/ROADMAP.md, docs/SPEC.md, and the active task before working.
The user approved continuing from M0 into M1 on 2026-11-05.

## Communication and safety
- Communicate with the user in Russian. Code, commit messages, comments, ADRs and documentation are in English; app UI is localized initially to Russian via ARB.
- The real cloud is a private personal account: never print, commit, log or include credentials, personal file names, raw WebDAV XML or account identifiers in screenshots, tests or task output.
- Read live WebDAV only when an explicit stage/task requires it. Do not run live WebDAV experiments again for M1. Never modify or delete cloud data.
- Read secrets only from explicitly provided environment variables; never paste them into commands, source code, docs or PRs.
- Never introduce Google Mobile Services (GMS), Firebase, telemetry, analytics or Google Play dependencies.
- Source is restricted to /AllMusic via Cloud Mail.ru WebDAV.
- No playlists, favorites, equalizer, lyrics, ALAC support, or invented extra features.

## Scope
- M0 read-only connectivity completed in a bounded Codex experiment; the dated summary is in docs/webdav-notes.md. The detailed local report commit b48d785 was not yet available on remote main when this handoff was prepared.
- Active stage: M1, Flutter scaffold, navigation, localization, theme, dependency injection and platform build setup, governed by docs/M1_CODEX_TASK.md.
- M2+ (WebDAV index, SQLite, covers, playback) are not authorized by the M1 task. Do not implement them prematurely.

## Engineering conventions
- Work in a feature branch and submit a Draft PR; do not merge without user approval.
- Plan each small change, then run formatter, analyzer, tests and platform build checks that the available environment actually supports.
- Never claim an Android or Windows binary was built unless the actual corresponding build command succeeded.
- Do not disable or delete failed tests; document the real blocker.
- Choose verified dependency versions, pin them in pubspec.lock, and document consequential decisions in docs/adr.
- Prefer framework widgets and a simple modular structure. Avoid heavy code generation, placeholder infrastructure and speculative abstractions.
- Update docs/STATUS.md and docs/ROADMAP.md with each milestone; include commands and meaningful test results.
- Windows native build needs a Windows runner / Visual Studio toolchain, not a Linux VM. Android build needs JDK and Android SDK. Do not silently skip either.
