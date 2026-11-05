import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'settings_page.dart';
import 'state.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const railBreakpoint = 720.0;
  static const icons = [
    Icons.music_note_outlined,
    Icons.album_outlined,
    Icons.people_outline,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final labels = [
      strings.tracks,
      strings.albums,
      strings.artists,
      strings.settings,
    ];
    final destination = ref.watch(destinationProvider);
    void select(int index) => ref
        .read(destinationProvider.notifier)
        .select(AppDestination.values[index]);

    final page = destination == AppDestination.settings
        ? const SettingsPage()
        : LibraryEmptyState(destination: destination);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= railBreakpoint;
        return Scaffold(
          appBar: AppBar(title: Text(strings.appTitle)),
          body: SafeArea(
            child: Row(
              children: [
                if (wide) ...[
                  NavigationRail(
                    key: const ValueKey('navigation-rail'),
                    selectedIndex: destination.index,
                    onDestinationSelected: select,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (var i = 0; i < labels.length; i++)
                        NavigationRailDestination(
                          icon: Icon(icons[i]),
                          label: Text(labels[i]),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: page,
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  key: const ValueKey('navigation-bar'),
                  selectedIndex: destination.index,
                  onDestinationSelected: select,
                  destinations: [
                    for (var i = 0; i < labels.length; i++)
                      NavigationDestination(
                        icon: Icon(icons[i]),
                        label: labels[i],
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({required this.destination, super.key});

  final AppDestination destination;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final title = switch (destination) {
      AppDestination.tracks => strings.tracks,
      AppDestination.albums => strings.albums,
      AppDestination.artists => strings.artists,
      AppDestination.settings => strings.settings,
    };
    return SingleChildScrollView(
      key: ValueKey('page-${destination.name}'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 16),
          Text(
            strings.libraryDisconnected,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(strings.libraryHint),
        ],
      ),
    );
  }
}

