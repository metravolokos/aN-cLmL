import 'package:cloudmail_player/cloud/cloud_mail_webdav.dart';
import 'package:cloudmail_player/data/library/catalog_import_progress.dart';
import 'package:cloudmail_player/data/library/cloud_music_service.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingCatalog extends CloudMusicService {
  _FailingCatalog({required this.failMetadata});

  final bool failMetadata;

  @override
  Future<List<RemoteTrack>> readCachedCatalog() async => const [];

  @override
  Future<List<RemoteTrack>> loadCatalog({
    void Function(int receivedBytes)? onResponseBytes,
  }) async {
    if (!failMetadata) {
      throw const CloudMailException(CloudMailErrorCode.invalidResponse);
    }
    return const [RemoteTrack(path: 'sample.flac', sizeBytes: 100)];
  }

  @override
  Future<void> scanMetadata({
    void Function(List<RemoteTrack> tracks, int done, int total)? onProgress,
    void Function(int total)? onStarted,
    bool Function()? isCancelled,
  }) async {
    throw StateError('a fake fixture failure that must not reach UI');
  }
}

void main() {
  test('listing failures report sanitized stage and error code', () async {
    final fixture = _FailingCatalog(failMetadata: false);
    final container = ProviderContainer(overrides: [
      cloudMusicServiceProvider.overrideWithValue(fixture),
    ]);
    addTearDown(container.dispose);
    addTearDown(fixture.close);

    await container.read(cloudCatalogProvider.notifier).refresh();

    final progress = container.read(catalogImportProgressProvider);
    expect(progress.phase, CatalogImportPhase.failed);
    expect(progress.failureStage, CatalogFailureStage.listing);
    expect(progress.failureCode, CloudMailErrorCode.invalidResponse);
    expect(container.read(cloudCatalogProvider).hasError, isTrue);
  });

  test('metadata failures preserve an already loaded file list', () async {
    final fixture = _FailingCatalog(failMetadata: true);
    final container = ProviderContainer(overrides: [
      cloudMusicServiceProvider.overrideWithValue(fixture),
    ]);
    addTearDown(container.dispose);
    addTearDown(fixture.close);

    await container.read(cloudCatalogProvider.notifier).refresh();

    final progress = container.read(catalogImportProgressProvider);
    expect(progress.phase, CatalogImportPhase.failed);
    expect(progress.failureStage, CatalogFailureStage.metadata);
    expect(progress.failureCode, isNull);
    expect(container.read(cloudCatalogProvider).asData?.value, hasLength(1));
  });
}
