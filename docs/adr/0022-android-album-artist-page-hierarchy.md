# ADR-0022: Album and artist detail-page visual hierarchy

Date: 2026-11-07. Status: implementation proposed for Android device verification.

## Decision
- Album: centered, prominent embedded artwork with restrained color accent; album title and artist; factual count, known total duration and file-format chips; one filled icon-only Play and one outlined icon-only Shuffle button. Keep disc/track order and show the currently playing track using a distinctive row and equalizer icon. Play/Shuffle tooltips remain accessible despite hidden labels.
- Artist: decorative gradient, real album artwork as a visual fallback rather than a fabricated artist portrait; name, album count, track count, known total duration and formats; icon-only Play and Shuffle; album cards with artwork/counts and a track list.
- Reuse one CollectionSummary for both views. If any duration is missing, omit the total duration rather than publishing a misleading partial value. We have no reliable year, bit depth, genre/biography, popularity or artist portrait in the current indexed catalog. Do not display those as if known.
- Preserve the compact mini-player and four bottom tabs on detail routes. Album track numbers respect indexed disc/track tags.
- No new favorites, follows, offline downloads, cloud write actions or fake secondary buttons. These would be separate supported features if explicitly requested.

## Why
The on-device Huawei test on 2026-11-07 showed functional music/album/artist browsing, but the detail pages were too sparse and the prominent labeled Play/Shuffle buttons consumed excessive space. User approved a modern visual concept with icon-only primary actions and requested all related UI changes.

## Tests
- `test/collection_summary_test.dart` verifies complete and partial metadata.
- `test/album_detail_page_test.dart`, `test/artist_mini_player_layout_test.dart`, `test/detail_navigation_test.dart` cover icon actions, facts, track list, and persistent tabs.
- Full CI and on-device Huawei review are required to confirm rendering and usability.
