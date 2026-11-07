import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/state.dart';
import '../l10n/app_localizations.dart';

/// The single persistent navigation bar owned by AppShell.
/// Detail pages never create a copy or change this widget's location.
class AppBottomNavigationBar extends ConsumerWidget {
  const AppBottomNavigationBar({this.onDestinationSelected, super.key});

  /// Close content-level detail routes after a tab is selected.
  final VoidCallback? onDestinationSelected;

  static const icons = [
    Icons.home_outlined,
    Icons.music_note_outlined,
    Icons.album_outlined,
    Icons.people_outline,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final labels = [
      strings.home,
      strings.tracks,
      strings.albums,
      strings.artists,
    ];
    final destination = ref.watch(destinationProvider);
    return NavigationBar(
      key: const ValueKey('navigation-bar'),
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      selectedIndex: destination.index,
      onDestinationSelected: (index) {
        ref
            .read(destinationProvider.notifier)
            .select(AppDestination.values[index]);
        onDestinationSelected?.call();
      },
      destinations: [
        for (var i = 0; i < labels.length; i++)
          NavigationDestination(
            icon: Icon(
              icons[i],
              key: ValueKey('nav-${AppDestination.values[i].name}'),
            ),
            label: labels[i],
          ),
      ],
    );
  }
}
