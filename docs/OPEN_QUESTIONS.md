# Open questions and active assumptions — 2026-11-05

No user interruptions are required to proceed. The following unknowns do not authorize pretending a capability has been verified.

| Question | Current engineering assumption | Verification gate |
| --- | --- | --- |
| Target Linux distribution | Arch/CachyOS is the primary developer target; ALT Linux remains secondary | Build and smoke test each distro, including GLIBC and native libraries |
| GNOME 51 in ALT Linux | Unknown. Do not assume distribution packages GNOME 51 | Check ALT package repository and target image before declaring support |
| GNOME 51 Flatpak runtime | Verify availability; use a supported freedesktop runtime if necessary with documented deviation | Flatpak builder smoke test on actual runtime |
| Real credentials | This environment has no accessible account secret; keep login entirely inside OS secure storage | User-controlled device verification only |
| WebDAV rate limits | M0 sampled short 206 ranges; no reliable sustained rate-limit data | Bounded real-cloud benchmark before setting concurrency |
| 64 KiB or 128 KiB range cap | Prefer 64 KiB request size by default, as a conservative compatibility bound; existing isolated 128 KiB succeeded | Real measurement of 64 KiB; reject full GET |
| FLAC/audio player on Linux Wayland | Buildable libmpv + just_audio_media_kit is a candidate, not yet verified | Actual GNOME 51 + Wayland playback smoke |
| No GMS dependency | Audited debugRuntimeClasspath in PR #5; release binary still needs audit | Check release dependency graph and manifest |
| Credential storage in Flatpak | flutter_secure_storage_linux uses Secret Service; portal compatibility not yet tested on GNOME 51 | Real sandbox persistence test |
| Metadata normalization | /AllMusic appears flat; use tags for album and artist grouping, filename fallback | Verify isolated FLAC/MP3 fixtures and live sample |
| Audio cache | Maximum current+next temporary files, no persistence across relaunches | Cache tests and on-device playback/seek |

No staging artifact may be labelled release-ready until the acceptance checks in docs/PLATFORMS.md have passed.
