# Platform acceptance matrix

| Capability | Android (AOSP/no GMS) | Windows 10/11 | Linux x86_64 GNOME 51 Wayland |
| --- | --- | --- | --- |
| Flutter UI shell | built; user's Huawei smoke passed for earlier M1 | built; user's Windows smoke passed for earlier M1 | runner not yet generated; work in progress |
| Cloud WebDAV read-only client | M2-A debug CI passed; live verification pending | M2-A release build passed; live verification pending | must build with secure storage's Linux backend |
| Native audio FLAC + seek | not yet implemented in current code | not yet implemented | not yet implemented |
| OS-protected secret persistence | plugin built; runtime check pending | plugin built; runtime check pending | libsecret/Secret Service, Flatpak check pending |
| OS media integration | MediaSession required | SMTC required | MPRIS required |
| GMS-free | dependency graph debug audit passed in PR #5 | n/a | n/a |
| Packaging | debug APK exists; release signing pending | release folder build exists; MSIX pending | Flatpak/portable bundle pending |
| Wayland scaling | n/a | n/a | 100/125/150/200% manual tests pending |

## Build prerequisites

- Android: JDK 17, Android SDK, no Play Services runtime dependency.
- Windows: Visual Studio 2022 C++ Desktop tools and ATL for flutter_secure_storage.
- Ubuntu Linux CI: clang, cmake, ninja-build, pkg-config, libgtk-3-dev, libstdc++-12-dev, libsecret-1-dev, libsecret-1-0. libmpv-dev only when media playback is actually linked.
- Arch/CachyOS: clang, cmake, ninja, pkgconf, gtk3, libsecret; plus mpv/libmpv when media engine added.
- ALT Linux: exact names, GNOME version and packaging availability must be verified, not assumed.

## Manual checks still required

- Android: AOSP emulator without Google services, real Cloud Mail.ru account check, foreground/background audio, media panel, app restart and secure storage.
- Windows: full zipped folder launch, credentials, sound, seek, cache, media keys, safe error messages.
- GNOME 51 Wayland: launch, audio, MPRIS, system dark theme, 100–200% fractional scaling, libsecret persistence and portal behavior inside Flatpak.

Do not call any target environment verified on the strength of a Linux CI build alone.
