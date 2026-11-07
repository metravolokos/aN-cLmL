# ADR-0025: Bottom-up album/artist navigation inside persistent Android shell

Date: 2026-11-07. Status: candidate pending device UI acceptance.

## Problem
The artist and album screens were pushed on the root Navigator using
MaterialPageRoute, so they entered horizontally from the right, left an empty
AppBar strip above their content, and constructed a second MiniPlayer and
NavigationBar. The footer was visibly replaced/moved during transitions.

## Decision
- AppShell owns one persistent MiniPlayer and one NavigationBar (or one
  NavigationRail on wide layouts).
- AppShell has a nested content Navigator *only* in the body's expanded area,
  beneath the shell's fixed footer. Detail routes use PageRouteBuilder with
  vertical SlideTransition from Offset(0,1) to Offset.zero; reverse transition
  dismisses downward. Existing tab pages are the persistent base route.
- A tab tap, even on the currently selected tab, clears content detail routes
  and changes the base destination without replacing the navigation bar.
- Detail pages have no own AppBar, MiniPlayer, or bottom navigation widgets;
  their Back controls overlay the actual cover/hero. This eliminates the
  extra empty top toolbar. Android system back is forwarded through
  NavigatorPopHandler to the nested Navigator.
- The existing dedicated Now Playing route and Settings route are deliberately
  left on the root Navigator; this decision concerns album/artist detail routes
  entered from library tabs.
- No playback, indexing, cloud, cover-cache, or account changes. This is only
  presentation and navigation; no device acceptance is claimed from CI.

## Acceptance
Widget tests check bottom-to-top movement, no duplicate navigation bar,
identity and position stability of the original footer, nested detail return,
tab change dismissal and Android back. Verify on-device that animation rises
from the lower edge of content while bottom navigation remains immobile.
