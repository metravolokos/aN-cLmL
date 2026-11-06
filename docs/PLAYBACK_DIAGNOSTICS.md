# Playback failure diagnostics (Windows / Android / Linux)

Introduced after user-observed Windows playback failure on 2026-11-06. A working Cloud Mail login, catalog scan, tags, and album artwork **do not prove** the audio transport / backend can play.

When an error appears on `Now Playing`, record **only** the displayed failure code and the affected platform, file type (FLAC or MP3), and whether the file ever began playing. Never request or copy credentials, authenticated request URLs, HTTP headers, file paths, raw native exception messages, or private catalog filenames into a ticket.

| Code | Boundary | Next investigation |
| --- | --- | --- |
| `P01` | `AudioPlayer.setAudioSource` failed | Desktop libmpv/just_audio_media_kit + just_audio loopback stream bridge; startup range data |
| `P02` | `AudioPlayer.play` failed | Backend opening/decoder/output state |
| `P03` | Native player error event | Desktop libmpv/Media3 backend; seek/decoder; code may be generic |
| `P11-<CloudMailErrorCode>` | WebDAV Range request rejected / timed out | Strict 206, Content-Range, 64-KiB chunks, server or credentials |
| `P12` | Range returned unexpected bytes or a non-WebDAV exception | Streaming bridge, cache and file I/O |

The controller marks `playing=false` on every reported failure; the previous UI incorrectly displayed Pause alongside an error. When Play is tapped after failure, the current source is reopened without losing the queue. No new automatic network retries or transport replacement are introduced by this patch.

**Important limitations**: `P01` / `P03` may mask an underlying fault inside the just_audio local HTTP proxy and do not by themselves prove a codec issue. `P11` / `P12` can arrive on the proxy stream asynchronously. Hardware sound, Windows system output, Linux MPRIS and Huawei Bluetooth are not validated by GitHub CI.

Acceptance: Quality/Android/Windows/Linux CI green on exact HEAD, then a real Windows attempt to play known FLAC and MP3, plus Android regression. Record only evidence observed on the device in docs/STATUS.md. Avoid stress tests.
