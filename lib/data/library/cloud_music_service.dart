import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cloud/cloud_connection_service.dart';
import '../../cloud/cloud_mail_webdav.dart';
import '../../domain/remote_track.dart';
import '../db/catalog_database.dart';

/// Production session. Secrets remain behind this data layer, never in widgets.
class CloudMusicService {
  CloudMusicService({
    CloudMailWebDavClient? client,
    CloudCredentialVault? vault,
  }) : _client = client ?? CloudMailWebDavClient(),
       _vault = vault ?? FlutterSecureCredentialVault();

  final CloudMailWebDavClient _client;
  final CloudCredentialVault _vault;
  CloudCredentials? _credentials;
  CatalogDatabase? _catalog;
  String? _catalogFor;

  static const String _usernameKey = 'cloud_mail_username';
  static const String _passwordKey = 'cloud_mail_app_password';

  Future<CloudCredentials> _sessionCredentials() async {
    if (_credentials != null) return _credentials!;
    final user = await _vault.read(_usernameKey);
    final password = await _vault.read(_passwordKey);
    if (user == null || user.isEmpty || password == null || password.isEmpty) {
      throw const CloudMailException(CloudMailErrorCode.credentialsRequired);
    }
    return _credentials = CloudCredentials(
      username: user,
      appPassword: password,
    );
  }

  /// One Depth:1 list. No full-file downloads. The server listing is bounded.
  Future<List<RemoteTrack>> loadCatalog() async {
    final credentials = await _sessionCredentials();
    final entries = await _client.propfind(credentials, depth: 1);
    final tracks = <RemoteTrack>[];
    for (final entry in entries) {
      if (entry.isCollection || entry.relativePath.isEmpty) continue;
      final path = entry.relativePath;
      final ext = path.toLowerCase();
      if (!(ext.endsWith('.flac') ||
          ext.endsWith('.mp3') ||
          ext.endsWith('.m4a') ||
          ext.endsWith('.ogg') ||
          ext.endsWith('.opus') ||
          ext.endsWith('.wav'))) {
        continue;
      }
      final size = entry.sizeBytes;
      if (size == null || size <= 0) continue;
      tracks.add(RemoteTrack(path: path, sizeBytes: size, etag: entry.etag));
    }
    tracks.sort(
      (a, b) => a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()),
    );
    final catalog = await _getCatalog();
    await catalog.applyScan(tracks);
    return catalog.readTracks();
  }

  Future<CatalogDatabase> _getCatalog() async {
    final credentials = await _sessionCredentials();
    if (_catalog != null && _catalogFor == credentials.username) {
      return _catalog!;
    }
    await _catalog?.close();
    _catalogFor = credentials.username;
    return _catalog = await openAccountCatalog(credentials.username);
  }

  Future<List<RemoteTrack>> readCachedCatalog() async {
    try {
      final catalog = await _getCatalog();
      return catalog.readTracks();
    } on CloudMailException catch (error) {
      if (error.code == CloudMailErrorCode.credentialsRequired) {
        return const <RemoteTrack>[];
      }
      rethrow;
    }
  }

  Future<Uint8List> readRange(String path, int offset, int length) async {
    final credentials = await _sessionCredentials();
    return _client.getRange(
      credentials,
      path: path,
      offset: offset,
      length: length,
    );
  }

  void close() {
    _credentials = null;
    final catalog = _catalog;
    if (catalog != null) { unawaited(catalog.close()); }
    _client.close();
  }
}

final cloudMusicServiceProvider = Provider<CloudMusicService>((ref) {
  final service = CloudMusicService();
  ref.onDispose(service.close);
  return service;
});

class CloudCatalogController extends AsyncNotifier<List<RemoteTrack>> {
  @override
  Future<List<RemoteTrack>> build() async =>
      ref.read(cloudMusicServiceProvider).readCachedCatalog();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(cloudMusicServiceProvider).loadCatalog(),
    );
  }
}

final cloudCatalogProvider =
    AsyncNotifierProvider<CloudCatalogController, List<RemoteTrack>>(
      CloudCatalogController.new,
    );
