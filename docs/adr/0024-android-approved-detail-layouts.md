# ADR-0024: Approved Android artist and album screen compositions

Date: 2026-11-07. Status: candidate pending visual acceptance on device.

## Reference concepts

The approved visual references in the owner's ChatGPT Library are:

- `image-gen-2(6).png` — **Концепт страницы исполнителя** (wide landscape/artist header; artist name over background; factual stats and dominant playback control; track preview ahead of albums; persistent mini-player and navigation).
- `image-gen-1(6).png` — **Концепт страницы альбома** (prominent square artwork over a softly colored ambient backdrop; clear centered album title/artist; strong play action; compact metadata and track rows; persistent mini-player and navigation).

The earlier PR #15/#16 implemented only a feature checklist, not these visual compositions. This correction uses the above two screenshots as hierarchy references, instead of inventing new designs.

## Implementation decision

- Artist: replace the small centered square hero with a wide atmospheric banner, show the artist name on the banner, show a short track preview before the album grid; more than five tracks can be expanded in place to access the full collection without duplicating songs.
- Album: prominent square album artwork, tinted blurred backdrop sourced from the album's **actual** indexed cover, centered album title and actual artist, icon-only primary Play and secondary Shuffle, metadata following actions, compact disc-aware track list.
- Use existing cached album artwork for the ambient visual. There is no artist image source in the library and no network image or fake biography should be added.
- Preserve actual playback controls, disc/track sorting, all-track access, four bottom tabs, existing mini-player, and the standard Now Playing seek control.
- The current library does not index release year, genre, bit depth/sample rate, artist popularity, likes, follows, downloads or favorites. Do not reproduce those fictional sample values/buttons from the generated concept screenshots. The track preview is labeled simply **Tracks**, not **Popular tracks**, because no popularity data exists.
- Keep icon-only Play and Shuffle, as explicitly approved after the illustrations were generated.
- No new cloud requests other than reuse of the existing bounded thumbnail cache; no changes to audio/network paths.

## Verification

CI tests check hero and metadata presence, factual track ordering, artist track-first ordering, no loss of albums, navigation, and playback affordances. Successful widget tests do **not** prove pixel-level visual fidelity. Obtain an Android APK and compare screenshots with both reference images before final acceptance. The design remains a proposal until then.
