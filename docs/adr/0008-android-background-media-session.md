# ADR-0008: Android foreground MediaSession for Cloud Range playback

Date: 2026-11-05
Status: Proposed, pending device acceptance

## Context

Flutter UI and just_audio already stream encrypted authenticated WebDAV audio using bounded 64 KiB Range GETs. The Android app must continue playing while backgrounded and expose a true system media session with playback metadata and controls in the Android/EMUI media panel, rather than an ordinary unrelated notification. Bluetooth headset buttons and pause/resume/next/previous are required. The user prohibits GMS and wants normal system audio routing.

## Decision

Use the official just_audio_background adapter (pinned 0.0.1-beta.17) with audio_service (pinned 0.18.19) for the single just_audio player instance. The Android activity extends AudioServiceActivity. The manifest declares WAKE_LOCK, foreground mediaPlayback permissions, an AudioService and media button receiver. Initialize the background service before starting the Flutter app.

Only code in lib/platform/android imports audio_service or just_audio_background. A platform-injected MediaTagFactory creates Android MediaItem metadata from the local track title, album, artist, duration and relative path ID, then passes it as an opaque tag to the shared StreamAudioSource. No cloud login, password, Authorization header or signed credential URL is ever passed to the OS media session.

Keep WebDAV Range transport, cache and FLAC decoder selection unchanged. Windows and Linux continue to use the established media_kit backend, without Android media session initialization.

## Alternatives

- Direct Kotlin Media3 MediaSessionService plus a bidirectional Flutter channel: more control but duplicates playback command dispatch, lifecycle state and queue; defer unless the adapter proves inadequate.
- A generic persistent notification alone: rejected because the user explicitly requires system media controls.
- audio_service with a custom AudioHandler immediately: more flexible but unnecessary complexity for one player at the current vertical slice stage; consider if queue commands are not correctly exposed by the adapter.

## Validation gates

1. CI: Flutter analyzer, widget/unit tests, layer checker, Android debug APK, Windows release and Linux release.
2. Static Android manifest check for foreground mediaPlayback service, receiver and permission; Android GMS dependency audit.
3. AOSP Android runtime: media panel appears as a media session, correct track title, play/pause/seek/next/previous, headphone buttons, background and screen-off playback.
4. Huawei EMUI runtime: Bluetooth audio and media panel checked on the user device. Lock-screen visibility may depend on OEM policies and cannot be promised from source code.
5. Disconnect stops playback and invalidates credentials; no authenticated requests after logout.

This ADR describes planned integration and acceptance criteria; green CI alone does not establish a passing device or EMUI result.
