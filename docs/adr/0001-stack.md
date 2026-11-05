# ADR 0001: Flutter shell with Riverpod and generated localizations

Date: 2026-11-05
Status: Proposed implementation; dependency resolution and execution blocked

## Decision

Use one root Flutter app for Android and Windows, framework Material 3 widgets,
Flutter SDK localizations and ARB generation, and flutter_riverpod 3.0.3. Keep
navigation and theme as small Notifier providers under ProviderScope. Theme
selection is session-only for M1. At 720 logical pixels, switch NavigationBar to
NavigationRail without resetting destination state. Use scrollable, bounded
content and framework dropdown controls for small windows and accessibility.

Future cloud, storage and player contracts are isolated in `lib/domain`; M1
instantiates none. Actual service provider bindings belong to implementation
milestones. No networking, audio, persistence or secure-storage plugin is added.

The official Flutter stable repository was cloned on 2026-11-05 at revision
`c197ca5199e9ee5661e865596c9c07294dfab51c`, tag 3.47.9. Bootstrap requests engine
`89c39edfdfae2949f6806e4a315c0c08522238b7`. This is source provenance, not a
successful `flutter --version` result. Dart runtime version remains unverified.
All bootstrap attempts were denied by the proxy for storage.googleapis.com.

The Android/Windows runner files were rendered from that official SDK's app
and Kotlin templates because `flutter create` could not run. The Windows icon
comes from official pub.dev package flutter_template_images 5.0.0. Android
minSdk is explicitly 24; Gradle 9.3.1, AGP 9.1.0 and Kotlin 2.4.0 are the SDK
template defaults. No iOS, macOS, Linux or web platform is included. Reconcile
with `flutter create --no-pub --project-name cloudmail_player
--platforms=android,windows --org com.cloudmailplayer .` once SDK bootstrap works;
review the diff and preserve existing source/docs/tests.

Pub.dev's version-specific metadata confirms flutter_riverpod 3.0.3 requires
Dart ^3.7.0 and Flutter >=3.0.0. The project requires Dart >=3.10.0 for its Flutter
API usage. flutter_lints is pinned to 6.0.0. Transitive resolution is not verified:
no fabricated pubspec.lock is committed. Resolve, commit the real lockfile and
switch CI to --enforce-lockfile before accepting M1.

## Consequences

Framework widgets keep the shell small and testable. Generated messages avoid
hardcoded screen text. Widget tests cover destination switching, resize retention,
theme selection and a small viewport with enlarged text. Platform runners and CI
are prepared, but no executable, screenshot or successful Flutter check can be
claimed yet. M1 remains blocked rather than accepted on source inspection alone.
