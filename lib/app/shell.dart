import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cloud/cloud_connection_service.dart';
import '../cloud/cloud_mail_webdav.dart';
import '../data/audio/playback_controller.dart';
import '../data/library/cloud_music_service.dart';
import '../presentation/library_page.dart';
import '../presentation/mini_player.dart';
import '../l10n/app_localizations.dart';
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
        : CloudLibraryPage(destination: destination);

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
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayer(),
              if (!wide)
                NavigationBar(
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

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  bool _hasSavedCredentials = false;
  bool _connected = false;
  bool _disconnected = false;
  CloudMailErrorCode? _error;
  WebDavRequestCancellation? _cancellation;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSavedConnection());
  }

  @override
  void dispose() {
    _cancellation?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedConnection() async {
    try {
      final saved = await ref
          .read(cloudConnectionServiceProvider)
          .loadSavedConnection();
      if (!mounted) return;
      setState(() {
        _usernameController.text = saved.username ?? '';
        _hasSavedCredentials = saved.hasCredentials;
      });
    } on CloudMailException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.code);
    }
  }

  Future<void> _connect() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _connected = false;
        _disconnected = false;
        _error = CloudMailErrorCode.loginRequired;
      });
      return;
    }

    final cancellation = WebDavRequestCancellation();
    _cancellation = cancellation;
    setState(() {
      _busy = true;
      _connected = false;
      _disconnected = false;
      _error = null;
    });
    try {
      await ref
          .read(cloudConnectionServiceProvider)
          .connect(
            username: username,
            appPassword: _passwordController.text,
            cancellation: cancellation,
          );
      if (!mounted) return;
      await _resetAccountSession();
      if (!mounted) return;
      setState(() {
        _hasSavedCredentials = true;
        _connected = true;
      });
    } on CloudMailException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.code);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = CloudMailErrorCode.serviceUnavailable);
    } finally {
      if (mounted) _passwordController.clear();
      _cancellation = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  void _cancelConnect() => _cancellation?.cancel();

  /// Close old authenticated readers when changing or removing credentials.
  Future<void> _resetAccountSession() async {
    try {
      await ref.read(playbackControllerProvider.notifier).stop();
    } catch (_) {
      // Credential invalidation must proceed even if audio shutdown fails.
    }
    if (!mounted) return;
    ref.invalidate(cloudMusicServiceProvider);
    ref.invalidate(cloudCatalogProvider);
  }

  Future<void> _disconnect() async {
    setState(() {
      _busy = true;
      _connected = false;
      _disconnected = false;
      _error = null;
    });
    try {
      await ref.read(cloudConnectionServiceProvider).disconnect();
      if (!mounted) return;
      await _resetAccountSession();
      if (!mounted) return;
      setState(() {
        _hasSavedCredentials = false;
        _disconnected = true;
        _usernameController.clear();
        _passwordController.clear();
      });
    } on CloudMailException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.code);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = CloudMailErrorCode.secureStorageUnavailable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(AppLocalizations strings, CloudMailErrorCode error) {
    return switch (error) {
      CloudMailErrorCode.loginRequired => strings.connectionLoginRequired,
      CloudMailErrorCode.credentialsRequired =>
        strings.connectionCredentialsRequired,
      CloudMailErrorCode.invalidCredentials =>
        strings.connectionInvalidCredentials,
      CloudMailErrorCode.missingAllMusic ||
      CloudMailErrorCode.missingResource => strings.connectionMissingAllMusic,
      CloudMailErrorCode.timeout => strings.connectionTimeout,
      CloudMailErrorCode.cancelled => strings.connectionCancelled,
      CloudMailErrorCode.secureStorageUnavailable =>
        strings.connectionStorageError,
      CloudMailErrorCode.serviceUnavailable ||
      CloudMailErrorCode.invalidResponse ||
      CloudMailErrorCode.invalidPath ||
      CloudMailErrorCode.invalidRange => strings.connectionUnavailable,
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = ref.watch(themeProvider);
    final labels = {
      ThemeMode.system: strings.systemTheme,
      ThemeMode.light: strings.lightTheme,
      ThemeMode.dark: strings.darkTheme,
    };
    return ListView(
      key: const ValueKey('page-settings'),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          strings.settings,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<ThemeMode>(
          key: const ValueKey('theme-selector'),
          initialValue: theme,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: strings.theme,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final mode in ThemeMode.values)
              DropdownMenuItem(value: mode, child: Text(labels[mode]!)),
          ],
          onChanged: (mode) {
            if (mode != null) ref.read(themeProvider.notifier).select(mode);
          },
        ),
        const SizedBox(height: 32),
        Text(strings.connection, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(strings.connectionDescription),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('cloud-login-field'),
          controller: _usernameController,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username],
          decoration: InputDecoration(
            labelText: strings.cloudLogin,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('cloud-password-field'),
          controller: _passwordController,
          enabled: !_busy,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: strings.externalAppPassword,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_hasSavedCredentials) ...[
          const SizedBox(height: 8),
          Text(strings.connectionSavedHint),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (_busy)
              OutlinedButton.icon(
                key: const ValueKey('cancel-connection-button'),
                onPressed: _cancelConnect,
                icon: const Icon(Icons.close),
                label: Text(strings.connectionCancel),
              )
            else
              FilledButton.icon(
                key: const ValueKey('connect-button'),
                onPressed: _connect,
                icon: const Icon(Icons.cloud_outlined),
                label: Text(strings.connect),
              ),
            OutlinedButton.icon(
              key: const ValueKey('disconnect-button'),
              onPressed: _busy ? null : _disconnect,
              icon: const Icon(Icons.link_off),
              label: Text(strings.disconnect),
            ),
          ],
        ),
        if (_busy || _connected || _disconnected || _error != null) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_busy) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                ] else ...[
                  Icon(
                    _connected || _disconnected
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    color: _connected ? Colors.green : null,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    _busy
                        ? strings.connectionChecking
                        : _connected
                        ? strings.connectionSuccess
                        : _disconnected
                        ? strings.connectionDisconnected
                        : _messageFor(strings, _error!),
                    key: const ValueKey('connection-status'),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(strings.source),
      ],
    );
  }
}
