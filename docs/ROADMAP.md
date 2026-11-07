# Android-only roadmap

Source history and the verbatim original three-platform specification are preserved, but only Android remains in scope.

| Priority | Item | Acceptance |
|---|---|---|
| P0 | Independent Android project | Android-only app entry, dependency lockfile, Android/Quality CI green on exact HEAD; original Git history preserved |
| P0 | Physical Huawei /AllMusic integration | Saved session/login, catalog refresh with progress, FLAC/MP3 real playback, pause/seek/next, artwork and safe logs |
| P0 | Playback race/recovery | Reproduce and guard stale events/stop/retry, no unexpected network or restart; regression tests |
| P1 | Android media integration | Background Media3/AudioService, media panel, headset/BT/USB DAC/call/audio focus on physical GMS-free phone |
| P1 | Distribution | One standard GMS-free Android APK now; later provide a stable owner-signed install/update path, without adding ABI- or vendor-specific pipelines unless requested |
| P1 | Catalog scalability | Interrupted indexing recovery, migration tests, 50k paging and memory budgets |
| P2 | Mobile UX refinement | Follow Android specification and Symfonium-inspired Russian UI plan; avoid desktop layout requirements |
| P2 | Publication and provenance | Third-party licence/codec review, structured acceptance evidence, searchable historical PR decisions |

Process: small focused PRs with exact-HEAD tests, historical rationale and clear distinction between source/build checks and device acceptance. No changes to the upstream repository.
