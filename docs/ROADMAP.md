# Roadmap

| Milestone | Status | Acceptance focus |
| --- | --- | --- |
| M0 | Done (bounded) | Live read-only Cloud Mail.ru HTTPS PROPFIND and 206 Range, report without secrets |
| M1 | In Draft PR; validation blocked | Flutter Android/Windows scaffold; Russian ARB strings; responsive navigation and theme; minimal DI; tests and CI |
| M2 | Not started | WebDAV client, indexing, SQLite, incremental sync and local fake WebDAV integration tests |
| M3 | Not started | Tracks/albums/artists media library, search, artwork cache |
| M4 | Not started | Functional audio engine, queue, Now Playing and mini-player |
| M5 | Not started | Bounded current/next-track audio cache, preloading, cancellation |
| M6 | Not started | Shuffle, repeat, persistence |
| M7 | Not started | Android media session / foreground media playback; Windows media keys / SMTC |
| M8 | Not started | Finishing, performance, GMS-free release APK, Windows release build |

## Milestone discipline

M1 is a functional UI shell, not a playback demo. A cloud request, a mocked playable track or a fake player control is not a substitute for real playback in M4. No long endurance or multi-hour tests without concrete justification and user approval.

M1 implementation and blockers: [STATUS](STATUS.md). Complete SDK setup, lockfile,
Flutter checks and native build verification before marking M1 done. M2 remains
not started and requires the next explicit milestone instruction.
