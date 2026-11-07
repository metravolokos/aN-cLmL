import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/presentation/collection_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('album and artist stats use only complete indexed duration', () {
    final summary = CollectionSummary.fromTracks(const [
      RemoteTrack(
        path: 'a.flac',
        sizeBytes: 300,
        duration: Duration(minutes: 2),
      ),
      RemoteTrack(
        path: 'b.mp3',
        sizeBytes: 300,
        duration: Duration(minutes: 3),
      ),
    ]);
    expect(summary.trackCount, 2);
    expect(summary.formats, ['FLAC', 'MP3']);
    expect(summary.totalDuration, const Duration(minutes: 5));
  });

  test('unknown duration is omitted, never a misleading partial total', () {
    final summary = CollectionSummary.fromTracks(const [
      RemoteTrack(
        path: 'a.flac',
        sizeBytes: 300,
        duration: Duration(seconds: 40),
      ),
      RemoteTrack(path: 'b.flac', sizeBytes: 300),
    ]);
    expect(summary.trackCount, 2);
    expect(summary.formats, ['FLAC']);
    expect(summary.totalDuration, isNull);
    expect(CollectionSummary.fromTracks(const []).totalDuration, isNull);
  });
}
