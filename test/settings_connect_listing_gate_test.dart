import 'dart:async';

import 'package:cloudmail_player/app/app.dart';
import 'package:cloudmail_player/cloud/cloud_connection_service.dart';
import 'package:cloudmail_player/cloud/cloud_mail_webdav.dart';
import 'package:cloudmail_player/data/library/cloud_music_service.dart';
import 'package:cloudmail_player/data/library/catalog_import_progress.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Connection implements CloudConnectionService {
  @override
  Future<SavedConnectionInfo> loadSavedConnection() async =>
      const SavedConnectionInfo(hasCredentials: false);

  @override
  Future<void> connect({
    required String username,
    required String appPassword,
    WebDavRequestCancellation? cancellation,
  }) async {}

  @override
  Future<void> disconnect() async {}
}

class _Catalog extends CloudMusicService {
  final Completer<List<RemoteTrack>> listing = Completer<List<RemoteTrack>>();
  int loadCalls = 0;

  @override
  Future<List<RemoteTrack>> readCachedCatalog() async => const [];

  @override
  Future<List<RemoteTrack>> loadCatalog({
    void Function(int receivedBytes)? onResponseBytes,
  }) {
    loadCalls++;
    return listing.future;
  }

  @override
  Future<void> scanMetadata({
    void Function(List<RemoteTrack> tracks, int done, int total)? onProgress,
    void Function(int total)? onStarted,
    bool Function()? isCancelled,
  }) async {
    onStarted?.call(0);
  }
}

Future<void> _enterCredentials(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('home-settings')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('cloud-login-field')),
    'fixture@example.invalid',
  );
  await tester.enterText(
    find.byKey(const ValueKey('cloud-password-field')),
    'local-test-secret',
  );
  await tester.tap(find.byKey(const ValueKey('connect-button')));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('Connect stays in Settings until remote list is available', (
    tester,
  ) async {
    final catalog = _Catalog();
    addTearDown(catalog.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudConnectionServiceProvider.overrideWithValue(_Connection()),
          cloudMusicServiceProvider.overrideWithValue(catalog),
        ],
        child: const CloudMailApp(),
      ),
    );
    await tester.pumpAndSettle();
    await _enterCredentials(tester);
    expect(catalog.loadCalls, 1);
    expect(find.byKey(const ValueKey('page-settings')), findsOneWidget);
    expect(find.byKey(const ValueKey('page-tracks')), findsNothing);

    catalog.listing.complete(const [
      RemoteTrack(path: 'Track.flac', sizeBytes: 12345),
    ]);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('page-tracks')), findsOneWidget);
    expect(find.text('Track'), findsOneWidget);
  });

  testWidgets('failed listing does not navigate to disconnected Tracks', (
    tester,
  ) async {
    final catalog = _Catalog();
    addTearDown(catalog.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudConnectionServiceProvider.overrideWithValue(_Connection()),
          cloudMusicServiceProvider.overrideWithValue(catalog),
        ],
        child: const CloudMailApp(),
      ),
    );
    await tester.pumpAndSettle();
    await _enterCredentials(tester);
    expect(catalog.loadCalls, 1);
    catalog.listing.completeError(
      const CloudMailException(CloudMailErrorCode.invalidResponse),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('page-settings')), findsOneWidget);
    expect(find.byKey(const ValueKey('page-tracks')), findsNothing);
    final scope = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('page-settings'))),
    );
    final progress = scope.read(catalogImportProgressProvider);
    expect(progress.phase, CatalogImportPhase.failed);
    expect(progress.failureStage, CatalogFailureStage.listing);
    expect(progress.failureCode, CloudMailErrorCode.invalidResponse);
  });
}
