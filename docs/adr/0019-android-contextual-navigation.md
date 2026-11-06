# ADR 0019 — Android home navigation and contextual search

Date: 2026-11-06
Status: proposed pending exact-head CI and Huawei UI acceptance

## Context

The imported Android app used four navigation destinations: Tracks, Albums, Artists and Settings. Its global app bar repeated the product name on every page and text search occupied a permanent row in each catalog view. The owner approved four primary content destinations — Home, Tracks, Albums and Artists — using icon-only navigation and a contextual search field as seen in reference Symfonium screenshots. These are interaction references, not assets to reproduce.

## Decision

- The Android home view is the only primary destination showing the product title in the app bar; it provides the entry to cloud/account/theme Settings and a shortcut to Tracks.
- Tracks, Albums, Artists use their own compact heading and refresh/search icons without a global app bar. Settings is a pushed route rather than a bottom tab, so account connection still remains accessible.
- Navigation icons have no visible labels, while localized labels remain in NavigationDestination semantics for screen readers. The selected destination must remain distinct through Material selection state.
- Each catalog tab starts with a collapsed search. Tapping its search icon shows an inline autofocus rounded search field; tapping again closes it and clears that tab's query. Search controllers are scoped per tab so switching tabs does not discard a still-open query.
- Preserve existing Unicode е/ё normalization and on-device filtering. Search must never issue unauthenticated cloud calls or send queries to the server.

## Validation

Widget tests cover four destinations, home-only title, settings route, connection transition to Tracks, and per-tab search reveal/retain/close. Check keyboard insets and narrow-screen accessibility on physical Android. This change does not modify playback, WebDAV or signing.
