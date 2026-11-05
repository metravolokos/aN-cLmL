# Roadmap

| Milestone | Status | Acceptance focus |
| --- | --- | --- |
| M0 | Completed (bounded) | Live authenticated /AllMusic WebDAV PROPFIND and 206 Range; safe report |
| M1 | Accepted (user + CI) | Flutter Android/Windows app scaffold, Russian UI, adaptive navigation, themes, all 3 CI jobs successful |
| M2 | Approved; M2-A next | Secure cloud connection, WebDAV transport, SQLite indexing, incremental sync and metadata extraction in small slices |
| M3 | Not started | Tracks/albums/artists media library, search, artwork cache |
| M4 | Not started | Functional audio engine, queue, Now Playing and mini-player |
| M5 | Not started | Current/next-track bounded audio cache, preloading, cancellation |
| M6 | Not started | Shuffle, repeat, persistence |
| M7 | Not started | Android media session and background playback; Windows media keys and SMTC |
| M8 | Not started | Final polish, performance, GMS-free release APK and Windows release |

## Delivery discipline

M1 acceptance: user verified successful starts on Android and Windows; GitHub Actions run #42013267771 completed Quality, Android and Windows successfully. A real lockfile was subsequently generated, and platform templates were reconciled with official Flutter generator.

M2 work items: [Issue #3](https://github.com/metravolokos/cloudmail-player-m0/issues/3), starting with M2-A. Each slice should provide short tests, a real build and a working user-visible result; avoid long endurance tests and architectural rework without specific defects.
