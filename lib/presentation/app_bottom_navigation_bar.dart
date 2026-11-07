import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/state.dart';
import '../l10n/app_localizations.dart';

/// One navigation bar shared by the library shell and artist/album details.
/// Detail routes live above AppShell: selecting a tab returns to that shell.
class AppBottomNavigationBar extends ConsumerWidget {
  const AppBottomNavigationBar({
    this.returnToShell = false,
    super.key,
  });

  final bool returnToShell;

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
        ref.read(destinationProvider.notifier).select(
          AppDestination.values[index],
        );
        if (returnToShell) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
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
