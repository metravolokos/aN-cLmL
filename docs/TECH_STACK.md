# Technology choices — 2026-11-05

| Module | Selected / candidate | Pin | Reason | Alternative / decision gate |
| --- | --- | --- | --- | --- |
| App & UI | Flutter, Material 3 | 3.47.9 | Existing Windows/Android shell verified in CI and by user | KMP/Tauri considered in ADR-0001 |
| HTTP + WebDAV | Dio | 5.11.1 | Existing tested M2-A source, cancellation and streamed bounded responses | Pooled dart:io HttpClient or platform-specific adapters; final selection pending measured transport comparison Issue #6 |
| XML | xml | 7.1.0 | Strict DAV response parsing | streaming XML parser for large listings |
| OS secrets | flutter_secure_storage | 11.2.0 | Keystore / Windows Credential Manager / Linux libsecret | secure OS platform adapter, manual password entry when unavailable |
| State | flutter_riverpod | 3.0.3 | Current testable app scaffold | built-in ChangeNotifier if simplicity warrants |
| SQLite | drift | 2.35.3 **candidate only** | built-in background isolate, FTS5, migration support | sqlite3 + SQL queries if drift package creates problems |
| Playback Android | just_audio | 0.10.6 **candidate only** | Media3/ExoPlayer on Android | media_kit |
| Playback Windows/Linux | just_audio_media_kit + libmpv | 2.1.0 **candidate only** | native decoding via media_kit | direct media_kit |
| Filesystem | path_provider | 2.1.6 **candidate only** | supported all three OSes | platform-specific directories |
| Linux desktop | Flutter GTK runner | 3.47.9 | Official supported Linux desktop backend | App runner changes only if needed |
| Media session | audio_service / smtc_windows / dbus | **unselected** | specific OS support required | custom adapters behind platform boundary |

**Important:** Candidate packages are not yet included in pubspec.yaml or claimed tested; installing unverified plugins without building all three platforms is prohibited. New decisions require ADR and a measured compatibility test. Drift >=2.32 no longer requires sqlite3_flutter_libs according to https://drift.simonbinder.eu/platforms/vm/.
