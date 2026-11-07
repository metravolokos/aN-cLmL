import 'package:flutter/material.dart';

/// Detail pages slide upward inside the library's content navigator.
///
/// On phones the AppShell keeps its one MiniPlayer and NavigationBar outside
/// this navigator, so neither can animate or be recreated by a detail route.
Future<void> openLibraryDetail(BuildContext context, Widget page) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      settings: const RouteSettings(name: '/library/detail'),
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
            key: const ValueKey('library-detail-slide'),
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  ),
                ),
            child: child,
          ),
    ),
  );
}
