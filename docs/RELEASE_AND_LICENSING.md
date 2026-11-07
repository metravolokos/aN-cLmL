# Release, provenance and distribution gates

**The project owner has not selected or authorized a project-wide source license.** Publication of the source on GitHub does not itself grant general rights to reuse, modify or redistribute it. Do not create a LICENSE file, declare MIT or another license, or release source or binaries to third parties under a project-wide license without explicit owner approval. Third-party dependencies and native binaries **retain their own licenses**; their notices and distribution obligations still apply. Release approval requires separate provenance review.

## Source prerequisites

- Verify ownership/authorization for all committed source, icons, illustrations, samples and bundled binaries. Confirm no personal music files, real cloud identifiers or secrets are committed, including **the full Git history**. Independently run a secret scanner on all refs; rotate exposed credentials if found.
- Generate a third-party Dart/Flutter/native dependency inventory from exact pubspec.lock and platform resolution, including direct/transitive licenses and system/native components. In particular review media_kit/libmpv/FFmpeg codec licensing, `dbus` MPL-2.0 and Rust/Cargokit dependencies; provide applicable notices/source offers if required. Do not guess LGPL/GPL compliance.
- For the active Android-only project, reproduce formatter, analyzer, tests, layer checks and the single standard Android APK build on the exact release commit; verify the GMS/Firebase runtime graph and manifest. Desktop checks belong to historical or separate projects.

## Platform artifacts and manual gates

Only the Android row below describes an **active** build in this repository. The Windows/Linux rows are retained as historical handover information; these platform artifacts are not produced by the Android-only CI.

| Platform | Current CI artifact | Release blocker |
| --- | --- | --- |
| Android (standard APK) | `flutter.yml` builds one `app-debug.apk` (`an-clml-android-debug` artifact), without GMS/Firebase runtime dependencies; no ABI-specific preview pipeline | Dedicated owner-managed release signing stored outside Git, consistent package/applicationId, versionCode/update path, GMS-free installation and real-device playback/headset/media-panel acceptance |
| Windows x64 | `flutter.yml` produces a Flutter release folder | Validate complete portable ZIP/installer, all native libraries and VC runtime, app display metadata, SmartScreen/signing policy and Windows 11 secure-store/SMTC/audio acceptance |
| Linux x86_64 | GNOME 51 Flatpak in `linux-flatpak-preview.yml`, 14-day CI artifact | Verify actual GNOME 51 Wayland launch, libmpv dynamic loading, sound, Secret Service persistence, MPRIS, sandbox policy and licensing/attribution before signing/distribution |

Development artifact retention is time-limited; linking to an old run is not a permanent release download. CI cannot prove sound, Bluetooth, VPN behavior, real cloud throughput or OEM media panels.

## Manual acceptance record template

Record (without user data): tested git SHA and artifact digest; OS version/device model (nonidentifying); installation method; connection success (yes/no); synthetic or real account (never username); audio FLAC/MP3, Pause/Resume, Seek, Next/Prev, Stop, cache reuse, network loss, logout; background/platform media commands; observed failure and reproducible minimal steps. Hardware PASS needs tested device and actual result, not a code review.

## Renaming and compatibility

The user-facing name is teStPlaYclouDE. Leave stable Dart package `cloudmail_player`, Android applicationId `com.cloudmailplayer.cloudmail_player`, Windows executable `cloudmail_player.exe`, Flatpak `com.cloudmailplayer.cloudmail_player` and existing artifact paths until an owner-approved migration includes signing, local DB/credentials and upgrade tests. Changing GitHub repository slug requires repository-settings access outside the current connector; URLs may redirect after an eventual rename.
