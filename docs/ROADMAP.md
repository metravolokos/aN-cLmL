# CloudMail Player — roadmap for the expanded three-platform assignment

| Stage | Current status | Gate |
| --- | --- | --- |
| M0 | Prior bounded Cloud Mail.ru WebDAV observation recorded; new Linux/media/Flatpak probe incomplete | Actual real account PROPFIND/Range and GNOME 51 compatibility tests |
| M1 | Windows and Android Flutter UI accepted previously; Linux runner generated, 3-OS CI configured | All three native CI builds and layer checker |
| M2 | Read-only WebDAV 207/206 client with secure storage exists; live list UI implemented; no SQLite index or sync yet | File listing, drift SQLite with checkpoints and bounded tag reads |
| M3 | Initial tracks list with filename fallbacks; no real artist/album tags or cover images yet | FLAC/MP3 and grouping + artwork cache |
| M4 | First seekable remote audio source written using just_audio and 64 KiB Range; not device verified | Actual playback, seek and queue on all three OSes |
| M5 | Not implemented | Current+next disk cache, bounded prefetch and cleanup |
| M6 | Not implemented | Shuffle/repeat/persistence |
| M7 | Not implemented | Android media session, Windows SMTC, Linux MPRIS |
| M8 | Not implemented | Performance measurements, error handling and scaling |
| M9 | Not implemented | Signed release APK, Windows archive/installer and Flatpak validation |

No stage is accepted by writing source code alone. Tests and builds do not demonstrate real audio playback, GNOME Wayland/MPRIS or Cloud Mail.ru access on the user's devices.
