# Android-only bootstrap and migration plan

Status: staged Android-only entry point and CI scope, **not** completed platform extraction.

## Source preservation

- The full original Git ancestry and source/experimental refs were imported into `aN-cLmL` without rewriting original commit objects.
- `docs/USER_SPEC_RU.md` is the **historical original specification**. Do not delete or edit it; desktop material there describes the original plan, not current Android scope.
- `docs/history/` is proposed in draft PR #3. This Android bootstrap PR does not depend on that draft, and neither PR should be merged without review.
- `cloudmail-player-m0` is a read-only historical source for this migration; changes belong only in `aN-cLmL`.

## Active Android scope

- Flutter 3.47.9, Dart 3.13.7, API 24+, **no GMS**.
- Flutter UI, Dio WebDAV, Drift catalog, bounded FLAC/MP3 tag/art readers, current+next temporary cache.
- `just_audio` through Android Media3, `audio_service` foreground MediaSession and `audio_session` focus.
- Cloud Mail.ru read-only fixed `/AllMusic`; no redirects with credentials; each Range GET <= 64 KiB and 206 validated.
- Build and quality checks only for Android. Physical Huawei/real WebDAV/audio acceptance remains outstanding.

## Explicitly deferred cleanup

The first bootstrap change removes Windows/Linux initialization from the app entry point and limits the required CI matrix to quality plus Android. It does **not** yet delete native desktop runners, platform adapters, associated tests, original documentation, or desktop dependencies from `pubspec.yaml`.

These remain temporarily to avoid claiming an untested dependency/lockfile migration. Subsequent focused PR must:
1. Remove unused desktop adapters, runners, Flatpak packaging and desktop-only tests from the **current tree**, keeping original Git history intact.
2. Remove desktop-only dependencies from `pubspec.yaml`, regenerate `pubspec.lock` using pinned Flutter/Dart, and verify `flutter pub get --enforce-lockfile`.
3. Retire desktop-only workflows and update old three-platform assertions in current documentation, while preserving them in historical originals.
4. Run quality + Android CI on exact PR HEAD; produce only the standard `app-debug.apk` from `.github/workflows/flutter.yml`; perform device/cloud verification independently of CI. Do not reinstate a separate ARM64 or vendor-specific workflow unless explicitly requested.

## Merge gates

Never merge an unreviewed draft or equate a green build with audio playback. Preserve legacy Android package/application ID for install continuity, until signing and update migration is a separate reviewed decision. Avoid any source Git-history rewrite. Do not disable secret scanning or weaken WebDAV limits.
