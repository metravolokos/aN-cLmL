# CloudMail Player — current roadmap (2026-11-05)

| Stage | Implemented source status | Remaining acceptance |
| --- | --- | --- |
| M0 | Initial WebDAV behavior and multi-platform tooling documented | Real Cloud Mail.ru bounded live checks and GNOME 51 investigation |
| M1 | Flutter shell, Russian UI, three-platform native runners and CI | Device launch check for current integrated binary on all three systems |
| M2 | Secure WebDAV, SQLite incremental catalog and bounded FLAC/MP3 scanner | Actual authenticated indexing, recovery and performance checks |
| M3 | Tracks/albums/artists and text search | Embedded art integration, album image grid, safe thumbnail LRU |
| M4 | Remote seekable playback, queue, Now Playing and mini-player | Audible real-device stream, seek, Next, Pause/Resume and handoff |
| M5 | Temporary current+next cache and background prefetch | Live cache behavior; no stale files or extra GET on cached seek |
| M6 | Shuffle, repeat and queue logic | Persistence across app restart and end-to-end behavior |
| M7 | Not yet integrated | Android foreground media session / BT / audio focus, Windows SMTC, Linux MPRIS |
| M8 | Selected validations and graceful error handling | 50k indexing, artwork memory budget, UX and error recovery |
| M9 | Development APK/Windows/Linux bundles via CI | Release signing, Windows delivery, Linux Flatpak and manual platform checks |

**Acceptance rule:** a source commit or successful binary build is not proof that the feature works with an authenticated account and physical devices. Avoid describing M0–M9 as complete until these acceptance checks pass.

**Priorities:** stabilize current playback and artwork, verify real Cloud Mail.ru playback, integrate platform media sessions, then package deliverables. Do not reimplement functionality that already exists on main without a measured defect.
