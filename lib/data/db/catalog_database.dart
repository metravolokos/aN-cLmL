import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/remote_track.dart';

part 'catalog_database.g.dart';

/// Persistent catalog rows scoped to one account, independent of remote secrets.
class RemoteFiles extends Table {
  TextColumn get path => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get etag => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  IntColumn get generation => integer()();

  @override
  Set<Column<Object>> get primaryKey => {path};
}

@DriftDatabase(tables: [RemoteFiles])
class CatalogDatabase extends _$CatalogDatabase {
  CatalogDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  Future<List<RemoteTrack>> readTracks() async {
    final rows = await select(remoteFiles).get();
    final tracks = [
      for (final row in rows)
        RemoteTrack(
          path: row.path,
          sizeBytes: row.sizeBytes,
          etag: row.etag,
          title: row.title,
          artist: row.artist,
          album: row.album,
        ),
    ];
    tracks.sort(
      (a, b) => a.fileName.toLowerCase().compareTo(
        b.fileName.toLowerCase(),
      ),
    );
    return tracks;
  }

  /// The entire cloud listing commits atomically. Existing tags survive a
  /// repeated scan only when both ETag and size are unchanged.
  Future<void> applyScan(List<RemoteTrack> remote) async {
    final existing = {
      for (final row in await select(remoteFiles).get()) row.path: row,
    };
    final epoch = DateTime.now().microsecondsSinceEpoch;
    await transaction(() async {
      await batch((batch) {
        for (final file in remote) {
          final previous = existing[file.path];
          final sameFile = previous != null &&
              previous.etag == file.etag &&
              previous.sizeBytes == file.sizeBytes;
          batch.insert(
            remoteFiles,
            RemoteFilesCompanion.insert(
              path: file.path,
              sizeBytes: file.sizeBytes,
              generation: epoch,
              etag: Value(file.etag),
              title: Value(sameFile ? previous.title : file.title),
              artist: Value(sameFile ? previous.artist : file.artist),
              album: Value(sameFile ? previous.album : file.album),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      await (delete(remoteFiles)
            ..where((row) => row.generation.isNotValue(epoch)))
          .go();
    });
  }
}

/// One SQLite catalog per account, using a hashed identifier rather than the
/// user's email address in filenames. The DB is in the app support directory.
Future<CatalogDatabase> openAccountCatalog(String username) async {
  final support = await getApplicationSupportDirectory();
  final digest = sha256.convert(utf8.encode(username.toLowerCase())).toString();
  final path = p.join(support.path, 'music_${digest.substring(0, 24)}.sqlite');
  return CatalogDatabase(
    NativeDatabase.createInBackground(File(path)),
  );
}
