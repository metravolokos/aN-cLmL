# aN-cLmL — Android development and historical handover

This repository is the **Android-only continuation** of https://github.com/metravolokos/cloudmail-player-m0. The source repository is a read-only historical input for this migration: do not change it. Desktop platforms will be developed elsewhere, not here.

## Read before touching code

1. [Android active specification](docs/ANDROID_SPEC_RU.md)
2. [Original user specification](docs/USER_SPEC_RU.md) — immutable, historically cross-platform
3. [Android handover plan](docs/ANDROID_HANDOVER.md)
4. [Status](docs/STATUS.md), [roadmap](docs/ROADMAP.md), [decision index](docs/DECISION_INDEX.md), [development history](docs/DEVELOPMENT_HISTORY.md)
5. [Security audit](docs/PUBLIC_REPOSITORY_AUDIT.md) and [licensing status](docs/RELEASE_AND_LICENSING.md)
6. `docs/history/` if merged; source PR/issue refs at GitHub remain primary evidence.

## Engineering boundaries

- Android API 24+, Flutter pinned in `.fvmrc`, no Google Play Services/Firebase.
- Only read-only Cloud Mail.ru WebDAV over HTTPS at fixed `/AllMusic`; no credential redirects, no cloud writes; <=64 KiB per Range GET with strict 206 validation.
- Android Media3 + just_audio + audio_service + audio_session, system audio mixer. Windows/Linux integrations are historical; do not restore them in Android startup.
- Password only entered in UI and kept in platform secure storage. Never store secrets, private filenames, real credentials, URLs with auth, account identifiers or unsanitized diagnostic logs in code, PRs or CI. Rotate if a real leak is found.
- Keep domain/data/presentation free of platform package imports; system integration under `lib/platform/android`. Keep tests and Android CI on exact PR HEAD.
- Preserve original source history, ADR decisions, failed experiments and original spec. If historical rationale is undocumented, say so.
- No mocks as proof of live hardware acceptance. No speculative large rewrites, mass stress tests or blocking desktop requirements.

## Active PR and migration constraints

- The first Android-only bootstrap intentionally retains desktop runner files and dependencies until a separately validated lockfile/build cleanup. Do not mistake this intermediate state for the final Android-only source tree.
- Archive PR #3 and bootstrap PR #5 are separate drafts until checked. Their exact status can change: query GitHub.
- Add change-specific docs/ADRs and regression tests; run format, analyze, tests, APK build and no-GMS graph check; do not merge on partial CI.
- Apply Android user acceptance to actual Huawei device; lock-screen/EMUI behavior must be observed, not inferred.
