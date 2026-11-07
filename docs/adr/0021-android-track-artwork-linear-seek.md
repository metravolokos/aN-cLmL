# ADR-0021: Track artwork rows and three-layer linear seek bar

Date: 2026-11-07. Status: seek-bar implementation superseded by ADR-0023 (2026-11-07); track artwork decision retained.

## Decision
- On the Tracks tab and the artist track list, show an existing account-scoped, bounded `AlbumCoverThumbnail` on the left, followed by the track title and the artist name. The contextual menu contains only supported Play and Open Album actions. Loading remains lazy for visible rows; missing artwork shows an icon rather than triggering an unbounded fallback.
- When Flutter reuses a thumbnail widget after scrolling or filtering, a change in path, ETag or file size restarts its thumbnail request, avoiding stale artwork. Reuse the current bounded cache and WebDAV data layer; no extra provider, credentials or remote requests at list-build time.
- Replace the decorative waveform in Now Playing with a 12 dp-high linear track: unbuffered background, partially cached region, and heard region. An overlaid thumb continues to invoke one seek only after the user ends a drag. Playback and cache progress are separate signals.
- Do not invent bit depth, release date, favorites or download functions from UI concepts; those require real metadata or a separately approved feature.

## Evidence
- User on Huawei confirmed active indexing, album artwork and playback, but requested Apple Music-style thumbnail/title/artist track rows and a wide standard buffered seek bar.
- Regression tests: `test/track_row_artwork_test.dart`, `test/now_playing_page_test.dart`, `test/now_playing_position_test.dart`; existing artist/album UI tests.

## Tradeoffs
- Existing FLAC embedded-artwork reader is the current thumbnail source. Files without a supported embedded image (including MP3 without an implemented APIC reader) intentionally show a placeholder.
- Color distinguishes played, downloaded and missing byte regions; this visual is not an actual decoded audio waveform.
