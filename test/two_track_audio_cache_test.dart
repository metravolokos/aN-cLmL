import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudmail_player/data/audio/two_track_audio_cache.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const current = RemoteTrack(path: 'Музыка/a.flac', sizeBytes: 131072);
const next = RemoteTrack(path: 'b.flac', sizeBytes: 65536);
const other = RemoteTrack(path: 'c.mp3', sizeBytes: 65536);

Future<TwoTrackAudioCache> makeCache(
  Directory directory,
  List<(String, int, int)> calls, {
  int maxBytes = 256 * 1024,
}) => TwoTrackAudioCache.create(
  directory: directory,
  maxBytes: maxBytes,
  reader: (path, offset, length) async {
    calls.add((path, offset, length));
    return Uint8List.fromList(
      List<int>.generate(length, (index) => (offset + index) % 251),
    );
  },
);

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cloudmail-cache-test-');
  });
  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('repeated seek uses cached pages and performs no new GET', () async {
    final calls = <(String, int, int)>[];
    final cache = await makeCache(directory, calls);
    await cache.activate(current, next);
    final first = await cache.read(current, 50000, 20000);
    expect(calls.length, 2);
    expect(calls.map((x) => x.$3), [65536, 65536]);
    final second = await cache.read(current, 50000, 20000);
    expect(second, first);
    expect(calls.length, 2);
    expect(first.first, 50000 % 251);
    await cache.close();
  });

  test('old track removed but next cache survives a track switch', () async {
    final calls = <(String, int, int)>[];
    final cache = await makeCache(directory, calls);
    await cache.activate(current, next);
    await cache.read(current, 0, 500);
    await cache.read(next, 0, 500);
    expect(calls.length, 2);
    await cache.activate(next, other);
    await cache.read(next, 0, 500);
    expect(calls.length, 2);
    expect(cache.progress(current), 0);
    expect(cache.progress(next), 1);
    final files = await directory.list().where((x) => x is File).toList();
    expect(files.length, lessThanOrEqualTo(2));
    await cache.close();
  });

  test('prefetch completely loads current before starting next', () async {
    final calls = <(String, int, int)>[];
    final cache = await makeCache(directory, calls);
    await cache.activate(current, next);
    await cache.prefetchCurrentThenNext();
    expect(calls.map((call) => call.$1), [
      current.path,
      current.path,
      next.path,
    ]);
    expect(cache.progress(current), 1);
    expect(cache.progress(next), 1);
    final files = await directory.list().where((x) => x is File).toList();
    expect(files.length, 2);
    expect(files.every((file) => file.path.endsWith('.cache')), isTrue);
    await cache.close();
  });

  test('hard limit sends oversized next-track requests direct to network', () async {
    final calls = <(String, int, int)>[];
    final cache = await makeCache(directory, calls, maxBytes: 131072);
    await cache.activate(current, next);
    await cache.read(next, 0, 4);
    expect(calls, [(next.path, 0, 4)]);
    expect(cache.progress(next), 0);
    await cache.prefetchCurrentThenNext();
    final files = await directory.list().where((x) => x is File).toList();
    expect(files.length, 1);
    expect(await files.first.length(), lessThanOrEqualTo(131072));
    await cache.close();
  });

  test('invalid response lengths are never marked cached', () async {
    final cache = await TwoTrackAudioCache.create(
      directory: directory,
      reader: (_, _, length) async => Uint8List(length - 1),
    );
    await cache.activate(current, next);
    await expectLater(
      cache.read(current, 0, 100),
      throwsA(isA<StateError>()),
    );
    expect(cache.progress(current), 0);
    await cache.close();
  });

  test('stale partial files are removed when a new cache starts', () async {
    final old = File(p.join(directory.path, 'orphan.part'));
    await old.writeAsBytes([1, 2, 3]);
    final cache = await makeCache(directory, []);
    expect(await old.exists(), isFalse);
    await cache.close();
  });

  test('invalid ranges are rejected before any network request', () async {
    final calls = <(String, int, int)>[];
    final cache = await makeCache(directory, calls);
    await cache.activate(current, next);
    await expectLater(
      cache.read(current, 0, 65537),
      throwsA(isA<RangeError>()),
    );
    await expectLater(
      cache.read(current, current.sizeBytes, 1),
      throwsA(isA<RangeError>()),
    );
    expect(calls, isEmpty);
    await cache.close();
  });

  test('simultaneous readers of the same block share one GET', () async {
    final calls = <(String, int, int)>[];
    final release = Completer<void>();
    final cache = await TwoTrackAudioCache.create(
      directory: directory,
      reader: (path, offset, length) async {
        calls.add((path, offset, length));
        await release.future;
        return Uint8List(length);
      },
    );
    await cache.activate(current, next);
    final a = cache.read(current, 0, 2048);
    final b = cache.read(current, 1024, 2048);
    release.complete();
    await Future.wait([a, b]);
    expect(calls.length, 1);
    await cache.close();
  });
}
