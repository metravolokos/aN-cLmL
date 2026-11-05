# CloudMail Player — Windows / Android / Linux

The project is a Flutter-based personal Cloud Mail.ru WebDAV audio player for
`https://webdav.cloud.mail.ru/AllMusic`. It has **no playlists, favorites,
Google Mobile Services, telemetry or analytics**.

The working branch `feature/three-platform-player-20261105` combines:
- A validated read-only WebDAV client with Basic Auth and OS-protected credentials.
- Russian Material 3 UI, theme controls, cloud connection settings.
- Bounded Depth:1 library listing and file-name-based tracks view.
- A **development-stage**, seekable, 64 KiB WebDAV Range audio source connected
  to just_audio (Android Media3) and just_audio_media_kit (Windows/Linux libmpv).
- Generated official Flutter runners for Windows, Android and Linux.

**Not a final released music player.** SQLite index, tag/cover parsing, audio
disk caching, full queue controls and OS background integrations are unfinished.
Runtime sound, credentials and GNOME 51 Wayland are not confirmed.

## Build

Use Flutter **3.47.9**, Dart **3.13.7** (pinned in `.fvmrc`).
Credentials are entered in the app, never in the source or CI.

```sh
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
python -m unittest discover -s tests -v
bash tools/check_layers.sh

flutter build apk --debug
flutter build windows --release   # Windows host + Visual Studio 2022 C++ and ATL
flutter build linux --release     # Linux host + GTK/libsecret development files
```

Linux Debian/Ubuntu development dependencies:
`clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev libsecret-1-dev`.
For Windows/Linux media playback, libmpv is bundled or supplied according to the
media_kit library package and the target packaging constraints. Release licensing
and actual GNOME 51 runtime tests are still required.

## Work and evidence

Read [AGENTS.md](AGENTS.md), [STATUS](docs/STATUS.md),
[ROADMAP](docs/ROADMAP.md), [PLATFORMS](docs/PLATFORMS.md),
[TECH STACK](docs/TECH_STACK.md) and [ARCHITECTURE](docs/ARCHITECTURE.md).

Cloud login requires an external-application password issued by the Cloud Mail.ru
account. Earlier passwords mentioned in conversations should be rotated before
new live use. Do not put account secrets in issues, test fixtures or logs.

Source is fixed to `/AllMusic`; requests never write or delete remote files.
