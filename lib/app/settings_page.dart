import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cloud/providers.dart';
import '../cloud/webdav_client.dart';
import '../l10n/app_localizations.dart';
import 'state.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _user = TextEditingController();
  final _password = TextEditingController();
  CloudCredentials? _savedCredentials;
  CancellationToken? _activeRequest;
  bool _busy = false;
  bool _verified = false;
  bool _showPassword = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSaved());
  }

  Future<void> _loadSaved() async {
    final strings = AppLocalizations.of(context)!;
    try {
      final saved = await ref.read(credentialVaultProvider).read();
      if (!mounted) return;
      setState(() {
        _savedCredentials = saved;
        _user.text = saved?.username ?? '';
        _message = saved == null ? strings.cloudDisconnected : strings.cloudSaved;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _message = strings.cloudStorageError);
    }
  }

  Future<void> _connect() async {
    final strings = AppLocalizations.of(context)!;
    final username = _user.text.trim();
    final typedPassword = _password.text;
    final password = typedPassword.isNotEmpty
        ? typedPassword
        : (_savedCredentials?.username == username
            ? _savedCredentials?.password ?? ''
            : '');
    if (username.isEmpty || password.isEmpty) {
      setState(() => _message = strings.cloudCredentialsNeeded);
      return;
    }
    final credentials = CloudCredentials(username, password);
    final token = CancellationToken();
    _activeRequest = token;
    setState(() {
      _busy = true;
      _verified = false;
      _message = strings.cloudChecking;
    });
    try {
      await ref.read(cloudProbeProvider).checkRoot(credentials, cancel: token);
      if (token.isCancelled) return;
      await ref.read(credentialVaultProvider).save(credentials);
      if (!mounted || token.isCancelled) return;
      setState(() {
        _verified = true;
        _savedCredentials = credentials;
        _password.clear();
        _message = strings.cloudConnected;
      });
    } on CloudException catch (error) {
      if (!mounted) return;
      setState(() => _message = switch (error.reason) {
        CloudFailure.unauthorized => strings.cloudUnauthorized,
        CloudFailure.missingRoot => strings.cloudMissingRoot,
        CloudFailure.network => strings.cloudNetworkError,
        CloudFailure.malformed => strings.cloudInvalidResponse,
        CloudFailure.cancelled => strings.cloudCancelled,
      });
    } on Object {
      if (!mounted) return;
      setState(() => _message = strings.cloudStorageError);
    } finally {
      if (identical(_activeRequest, token)) _activeRequest = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    final strings = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await ref.read(credentialVaultProvider).clear();
      if (!mounted) return;
      setState(() {
        _savedCredentials = null;
        _verified = false;
        _user.clear();
        _password.clear();
        _message = strings.cloudDisconnected;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _message = strings.cloudStorageError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _activeRequest?.cancel();
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = ref.watch(themeProvider);
    final themeLabels = {
      ThemeMode.system: strings.systemTheme,
      ThemeMode.light: strings.lightTheme,
      ThemeMode.dark: strings.darkTheme,
    };

    return ListView(
      key: const ValueKey('page-settings'),
      padding: const EdgeInsets.all(24),
      children: [
        Text(strings.settings,
            style: Theme.of(context).textTheme.headlineMedium),
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
              DropdownMenuItem(value: mode, child: Text(themeLabels[mode]!)),
          ],
          onChanged: (mode) {
            if (mode != null) ref.read(themeProvider.notifier).select(mode);
          },
        ),
        const SizedBox(height: 32),
        Text(strings.connection,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(strings.source),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('cloud-username'),
          controller: _user,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: strings.cloudUsername,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('cloud-password'),
          controller: _password,
          obscureText: !_showPassword,
          enableSuggestions: false,
          autocorrect: false,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: strings.cloudPassword,
            helperText: _savedCredentials == null
                ? strings.cloudPasswordHint
                : strings.cloudPasswordSavedHint,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: strings.cloudRevealPassword,
              onPressed: () => setState(
                () => _showPassword = !_showPassword,
              ),
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              key: const ValueKey('cloud-connect'),
              onPressed: _busy ? null : _connect,
              child: Text(strings.cloudConnect),
            ),
            OutlinedButton(
              key: const ValueKey('cloud-disconnect'),
              onPressed: _busy ? null : _disconnect,
              child: Text(strings.cloudDisconnect),
            ),
            if (_busy)
              OutlinedButton(
                key: const ValueKey('cloud-cancel'),
                onPressed: () => _activeRequest?.cancel(),
                child: Text(strings.cloudCancel),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_message != null)
          Text(
            _message!,
            key: const ValueKey('cloud-status'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        if (_verified)
          Icon(Icons.cloud_done, color: Theme.of(context).colorScheme.primary),
      ],
    );
  }
}
