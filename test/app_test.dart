import 'package:cloudmail_player/app/app.dart';
import 'package:cloudmail_player/app/state.dart';
import 'package:cloudmail_player/cloud/credential_vault.dart';
import 'package:cloudmail_player/cloud/providers.dart';
import 'package:cloudmail_player/cloud/webdav_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeVault implements CredentialVault {
  CloudCredentials? saved;
  @override
  Future<CloudCredentials?> read() async => saved;
  @override
  Future<void> save(CloudCredentials credentials) async {
    saved = credentials;
  }

  @override
  Future<void> clear() async {
    saved = null;
  }
}

class _FakeProbe implements CloudProbe {
  int calls = 0;
  @override
  Future<void> checkRoot(
    CloudCredentials credentials, {
    CancellationToken? cancel,
  }) async {
    calls++;
  }
}

Future<void> launch(
  WidgetTester tester,
  Size size, {
  CredentialVault? vault,
  CloudProbe? probe,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        credentialVaultProvider.overrideWithValue(vault ?? _FakeVault()),
        cloudProbeProvider.overrideWithValue(probe ?? _FakeProbe()),
      ],
      child: const CloudMailApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Russian narrow navigation switches every destination', (
    tester,
  ) async {
    await launch(tester, const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Библиотека не подключена'), findsOneWidget);
    for (final entry in {
      'Альбомы': 'albums',
      'Исполнители': 'artists',
      'Настройки': 'settings',
      'Треки': 'tracks',
    }.entries) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(entry.key),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('page-${entry.value}')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('wide rail navigates and retains selection across resizing', (
    tester,
  ) async {
    await launch(tester, const Size(1200, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('Альбомы'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('page-albums')), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      AppDestination.albums.index,
    );
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('page-albums')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme selector applies dark, light and system modes', (
    tester,
  ) async {
    await launch(tester, const Size(390, 844));
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    for (final entry in {
      'Тёмная': ThemeMode.dark,
      'Светлая': ThemeMode.light,
      'Как в системе': ThemeMode.system,
    }.entries) {
      await tester.tap(find.byKey(const ValueKey('theme-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.key).last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        entry.value,
      );
      if (entry.value != ThemeMode.system) {
        final context = tester.element(
          find.byKey(const ValueKey('page-settings')),
        );
        expect(
          Theme.of(context).brightness,
          entry.value == ThemeMode.dark ? Brightness.dark : Brightness.light,
        );
      }
    }
    expect(find.text('Облако не подключено'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small window and enlarged text remain scrollable', (
    tester,
  ) async {
    await launch(tester, const Size(320, 480));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('theme-selector')), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cloud connection stores verified credentials and disconnect clears them',
    (tester) async {
      final vault = _FakeVault();
      final probe = _FakeProbe();
      await launch(tester, const Size(390, 844), vault: vault, probe: probe);
      await tester.tap(find.text('Настройки'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('cloud-username')),
        'tester@example.invalid',
      );
      await tester.enterText(
        find.byKey(const ValueKey('cloud-password')),
        'dummy-password',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('cloud-connect')));
      await tester.tap(find.byKey(const ValueKey('cloud-connect')));
      await tester.pumpAndSettle();

      expect(probe.calls, 1);
      expect(vault.saved?.username, 'tester@example.invalid');
      expect(vault.saved?.password, 'dummy-password');
      expect(find.text('Подключено: /AllMusic доступна'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cloud-disconnect')));
      await tester.pumpAndSettle();
      expect(vault.saved, isNull);
      expect(find.text('Облако не подключено'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
