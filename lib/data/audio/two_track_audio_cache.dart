import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../domain/remote_track.dart';

typedef RemoteRangeReader = Future<Uint8List> Function(
  String path,
  int offset,
  int length,
);

/// A read-through, temporary current+next audio cache with a hard file budget.
class TwoTrackAudioCache {
  TwoTrackAudioCache._(this.directory, this._reader, this.maxBytes, this._owned);

  static const pageSize = 64 * 1024;
  static const defaultMaxBytes = 256 * 1024 * 1024;

  final Directory directory;
  final RemoteRangeReader _reader;
  final int maxBytes;
  final bool _owned;
  final Map<String, _Slot> _slots = {};
  Future<void> _writerQueue = Future<void>.value();
  String? _current;
  String? _next;
  int _generation = 0;
  bool _closed = false;

  static Future<TwoTrackAudioCache> create({
    required RemoteRangeReader reader,
    Directory? directory,
    int maxBytes = defaultMaxBytes,
  }) async {
    if (maxBytes < pageSize) throw ArgumentError.value(maxBytes, 'maxBytes');
    final owned = directory == null;
    final root = directory ??
        await Directory.systemTemp.createTemp('cloudmail-audio-');
    await root.create(recursive: true);
    // Never trust stale, partially downloaded pages from another process.
    await for (final entry in root.list(followLinks: false)) {
      if (entry is File &&
          (entry.path.endsWith('.part') || entry.path.endsWith('.cache'))) {
        await entry.delete();
      }
    }
    return TwoTrackAudioCache._(root, reader, maxBytes, owned);
  }

  static String _identity(RemoteTrack track) => sha256.convert(utf8.encode(
        track.path + '\u0000' + (track.etag ?? '') +
            '\u0000' + track.sizeBytes.toString(),
      )).toString();

  Future<T> _serialize<T>(Future<T> Function() work) {
    final completer = Completer<T>();
    _writerQueue = _writerQueue.then((_) async {
      try {
        completer.complete(await work());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  /// Keeps the selected track and one next track, preserving a warmed next.
  /// A track exceeding the budget is streamed directly, without a disk cache.
  Future<void> activate(RemoteTrack current, RemoteTrack? next) async {
    if (_closed) throw StateError('Cache closed');
    ++_generation;
    _current = _identity(current);
    _next = next == null ? null : _identity(next);
    final wanted = <String>{};
    var reserved = 0;
    for (final track in [current, if (next != null) next]) {
      final key = _identity(track);
      if (!wanted.contains(key) &&
          track.sizeBytes > 0 &&
          reserved + track.sizeBytes <= maxBytes) {
        wanted.add(key);
        reserved += track.sizeBytes;
      }
    }
    await _serialize(() async {
      for (final entry in _slots.entries.toList()) {
        if (!wanted.contains(entry.key)) {
          _slots.remove(entry.key);
          await entry.value.delete();
        }
      }
      for (final track in [current, if (next != null) next]) {
        final key = _identity(track);
        if (!wanted.contains(key) || _slots.containsKey(key)) continue;
        _slots[key] = _Slot(
          track,
          File(p.join(directory.path, '$key.part')),
          File(p.join(directory.path, '$key.cache')),
        );
      }
    });
  }

  Future<Uint8List> read(RemoteTrack track, int offset, int length) async {
    if (_closed) throw StateError('Cache closed');
    if (offset < 0 || length < 0 || length > pageSize ||
        offset + length > track.sizeBytes) {
      throw RangeError('Invalid audio range');
    }
    if (length == 0) return Uint8List(0);
    final slot = _slots[_identity(track)];
    if (slot == null) {
      final bytes = await _reader(track.path, offset, length);
      if (bytes.length != length) throw StateError('Short Range response');
      return bytes;
    }
    final output = BytesBuilder(copy: false);
    final end = offset + length;
    var at = offset;
    while (at < end) {
      final index = at ~/ pageSize;
      final page = await _readPage(slot, index);
      final pageOffset = index * pageSize;
      final from = at - pageOffset;
      final take = (end - at).clamp(0, page.length - from);
      if (take <= 0) throw StateError('Invalid cached page');
      output.add(Uint8List.sublistView(page, from, from + take));
      at += take;
    }
    return output.takeBytes();
  }

  static int _pageLength(RemoteTrack track, int index) {
    final remaining = track.sizeBytes - index * pageSize;
    return remaining < pageSize ? remaining : pageSize;
  }

  Future<Uint8List> _readPage(_Slot slot, int index) async {
    if (slot.cached.contains(index)) {
      final file = slot.finished ? slot.complete : slot.part;
      final handle = await file.open(mode: FileMode.read);
      try {
        await handle.setPosition(index * pageSize);
        final bytes = await handle.read(_pageLength(slot.track, index));
        if (bytes.length == _pageLength(slot.track, index)) {
          return Uint8List.fromList(bytes);
        }
      } finally {
        await handle.close();
      }
      slot.cached.remove(index);
    }
    final pending = slot.pending[index];
    if (pending != null) return pending;
    final future = _loadPage(slot, index);
    slot.pending[index] = future;
    try {
      return await future;
    } finally {
      slot.pending.remove(index);
    }
  }

  Future<Uint8List> _loadPage(_Slot slot, int index) async {
    final begin = index * pageSize;
    final length = _pageLength(slot.track, index);
    final bytes = await _reader(slot.track.path, begin, length);
    if (bytes.length != length) throw StateError('Short Range response');
    await _serialize(() async {
      if (_closed || !identical(_slots[_identity(slot.track)], slot) ||
          slot.cached.contains(index) || slot.finished) return;
      slot.writer ??= await slot.part.open(mode: FileMode.write);
      await slot.writer!.setPosition(begin);
      await slot.writer!.writeFrom(bytes);
      slot.cached.add(index);
      slot.cachedBytes += bytes.length;
      if (slot.cachedBytes == slot.track.sizeBytes) {
        await slot.writer!.flush();
        await slot.writer!.close();
        slot.writer = null;
        await slot.part.rename(slot.complete.path);
        slot.finished = true;
      }
    });
    return bytes;
  }

  /// Continues independently of Pause. A queue change cancels read-ahead.
  Future<void> prefetchCurrentThenNext() async {
    final generation = _generation;
    for (final id in [_current, _next]) {
      if (id == null) continue;
      final slot = _slots[id];
      if (slot == null) continue;
      final pages = (slot.track.sizeBytes + pageSize - 1) ~/ pageSize;
      for (var i = 0; i < pages; i++) {
        if (_closed || generation != _generation) return;
        try {
          await _readPage(slot, i);
        } catch (_) {
          // Foreground playback handles its own retries and failures.
          return;
        }
      }
    }
  }

  double progress(RemoteTrack track) {
    final slot = _slots[_identity(track)];
    if (slot == null || track.sizeBytes <= 0) return 0;
    return slot.cachedBytes / track.sizeBytes;
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _generation++;
    await _serialize(() async {
      for (final slot in _slots.values) {
        await slot.delete();
      }
      _slots.clear();
    });
    if (_owned && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

class _Slot {
  _Slot(this.track, this.part, this.complete);
  final RemoteTrack track;
  final File part;
  final File complete;
  final Set<int> cached = {};
  final Map<int, Future<Uint8List>> pending = {};
  RandomAccessFile? writer;
  int cachedBytes = 0;
  bool finished = false;

  Future<void> delete() async {
    final handle = writer;
    writer = null;
    if (handle != null) await handle.close();
    if (await part.exists()) await part.delete();
    if (await complete.exists()) await complete.delete();
    cached.clear();
  }
}
