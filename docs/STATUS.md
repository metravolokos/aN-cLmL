# Project status — 2026-11-05

## M0: bounded WebDAV connectivity — completed for moving forward

A Codex Cloud agent achieved HTTPS access via its standard proxy and authenticated with read-only PROPFIND. /AllMusic was confirmed; sampled HEAD and five Range requests succeeded. Content-Range uses bytes= syntax. Six offline tests passed. See docs/webdav-notes.md.

The agent reported local documentation commit b48d785da4a5a3d49254bdbc41e0f0ea4015eda9, but it was not pushed to GitHub when the M1 handoff was prepared. This status is reconstructed from its user-visible report, not a line-by-line review of that local commit.

## M1: implementation in Draft PR, validation blocked

Base: fresh origin/main `bffd03e8880a5d563e418c242b0cc96ca1909d6b`.
Branch: `feature/m1-flutter-scaffold`.
Draft PR: https://github.com/metravolokos/cloudmail-player-m0/pull/2.
The local-only M0 commit `b48d785da4a5a3d49254bdbc41e0f0ea4015eda9` is
not in this checkout's object database; the existing sanitized summary is retained.

Implemented source: root Flutter package, Android/Windows runner templates,
Android minSdk 24, Russian ARB configuration, Material 3, adaptive four-destination
navigation, Riverpod theme/navigation state, honest empty states, settings and
four focused widget tests. Future service contracts have no implementations.
No live requests, credentials, cloud files, audio plugins or M2 code were used.

### Verification on 2026-11-05

| Command / check | Actual result |
| --- | --- |
| `git fetch origin main` | Passed after network permission; expected base confirmed |
| `python -m unittest discover -s tests -v` | 6 tests passed |
| `git diff --check` | Passed for implementation commit |
| `flutter --version` | Bootstrap failed, exit 56, proxy CONNECT 403 for storage.googleapis.com |
| `dart --version` | Same bootstrap blocker; no runtime version confirmed |
| `dart format lib test` | Same bootstrap blocker; formatting unverified |
| `flutter gen-l10n` | Same bootstrap blocker; generated output unavailable |
| `flutter analyze` | Same bootstrap blocker; no analyzer result |
| `flutter test` | Same bootstrap blocker; 4 widget tests written, none executed |
| `flutter build apk --debug` | Same bootstrap blocker; also no local Android SDK; JDK 21.0.12.1 exists |
| `flutter build windows --release` | Bootstrap blocked; native build also requires Windows/VS, this host is Linux |

Official stable source is tag 3.47.9, revision
`c197ca5199e9ee5661e865596c9c07294dfab51c`; this is not a runtime version
measurement. See ADR 0001. Platform files were rendered from SDK templates,
not produced by a successful flutter create invocation. No pubspec.lock could
be resolved. No successful binary or runtime smoke test is claimed.

CI has separate Linux quality, Windows release and Android debug jobs with
15/20-minute limits and read-only repository permission. The first PR run
https://github.com/metravolokos/cloudmail-player-m0/actions/runs/41994305871
failed all three jobs before any recorded steps. The job-step API returned empty
lists; log downloads returned 404 BlobNotFound. The failure's underlying cause
could not be established with the available API, and is not attributed to code
or billing without evidence. No CI artifacts were produced or tested.

### Required to finish M1

1. Allow storage.googleapis.com in the managed environment's outbound policy;
   generic network permission was granted but did not change the proxy denial.
2. Bootstrap Flutter, record actual Flutter and Dart runtime versions, reconcile
   platform templates with flutter create and resolve/commit pubspec.lock.
3. Format, generate localization, analyze and execute widget tests; fix failures.
4. Obtain successful Android and Windows builds with their native toolchains;
   inspect the Actions run's annotations in GitHub if jobs still fail to start.
5. Update this evidence and the Draft PR checklist. M1 is not complete until
   these checks pass. Do not start M2 or merge automatically.

## Constraints

No GMS; no telemetry; only Cloud Mail.ru /AllMusic as future source. No playlists/favorites. Do not use live credentials during M1. Real cloud integration and audio playback are out of scope until their later milestones.
