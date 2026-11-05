import 'dart:math';

import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/domain/track_queue.dart';
import 'package:flutter_test/flutter_test.dart';

const files = [
  RemoteTrack(path: 'a.flac', sizeBytes: 1),
  RemoteTrack(path: 'b.flac', sizeBytes: 2),
  RemoteTrack(path: 'c.mp3', sizeBytes: 3),
  RemoteTrack(path: 'd.flac', sizeBytes: 4),
];

void main() {
  test('empty queue never produces a track', () {
    final queue = TrackQueue();
    expect(queue.current, isNull);
    expect(queue.next(), isNull);
    expect(queue.previous(), isNull);
    queue.load(const []);
    expect(queue.isEmpty, isTrue);
  });

  test('plays selected track and advances in source order', () {
    final queue = TrackQueue()..load(files, startIndex: 1);
    expect(queue.current?.path, 'b.flac');
    expect(queue.next()?.path, 'c.mp3');
    expect(queue.next()?.path, 'd.flac');
    expect(queue.next(), isNull);
    expect(queue.current?.path, 'd.flac');
  });

  test('repeat all wraps both directions at queue boundaries', () {
    final queue = TrackQueue()..load(files);
    queue.setRepeat(QueueRepeat.all);
    expect(queue.previous()?.path, 'd.flac');
    expect(queue.next()?.path, 'a.flac');
  });

  test('repeat one applies only to automatic advancement', () {
    final queue = TrackQueue()..load(files, startIndex: 1);
    queue.setRepeat(QueueRepeat.one);
    expect(queue.next(automatic: true)?.path, 'b.flac');
    expect(queue.next()?.path, 'c.mp3');
    expect(queue.previous()?.path, 'b.flac');
  });

  test('repeat off does not wrap when reaching beginning', () {
    final queue = TrackQueue()..load(files);
    expect(queue.previous(), isNull);
    expect(queue.current?.path, 'a.flac');
  });

  test('shuffle preserves selected item and every source item exactly once', () {
    final queue = TrackQueue(random: Random(42))
      ..load(files, startIndex: 2);
    queue.setShuffle(true);
    expect(queue.current?.path, 'c.mp3');
    final seen = <String>{queue.current!.path};
    for (var i = 1; i < files.length; i++) {
      final next = queue.next();
      expect(next, isNotNull);
      expect(seen.add(next!.path), isTrue);
    }
    expect(seen, files.map((x) => x.path).toSet());
    expect(queue.next(), isNull);
  });

  test('disabling shuffle restores original source position and order', () {
    final queue = TrackQueue(random: Random(1))
      ..load(files, startIndex: 2);
    queue.setShuffle(true);
    queue.setShuffle(false);
    expect(queue.current?.path, 'c.mp3');
    expect(queue.next()?.path, 'd.flac');
    expect(queue.previous()?.path, 'c.mp3');
  });

  test('repeating all in shuffle wraps to first shuffled entry', () {
    final queue = TrackQueue(random: Random(4))..load(files);
    queue.setShuffle(true);
    queue.setRepeat(QueueRepeat.all);
    final first = queue.current;
    for (var i = 0; i < files.length; i++) {
      queue.next();
    }
    expect(queue.current, same(first));
  });

  test('load preserves shuffle and repeat settings but resets track history', () {
    final queue = TrackQueue(random: Random(7))..load(files);
    queue.setRepeat(QueueRepeat.all);
    queue.setShuffle(true);
    queue.load(files.sublist(1), startIndex: 1);
    expect(queue.current?.path, 'c.mp3');
    expect(queue.shuffle, isTrue);
    expect(queue.repeat, QueueRepeat.all);
    expect(queue.length, 3);
  });

  test('load rejects invalid indices without replacing current list', () {
    final queue = TrackQueue()..load(files);
    expect(() => queue.load(files, startIndex: 4), throwsRangeError);
    expect(queue.current?.path, 'a.flac');
  });

  test('stopping clears queue but keeps selected playback modes', () {
    final queue = TrackQueue()..load(files);
    queue.setShuffle(true);
    queue.setRepeat(QueueRepeat.one);
    queue.clear();
    expect(queue.current, isNull);
    expect(queue.next(automatic: true), isNull);
    expect(queue.shuffle, isTrue);
    expect(queue.repeat, QueueRepeat.one);
  });
}
