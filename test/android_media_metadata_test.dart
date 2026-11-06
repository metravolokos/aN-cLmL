import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/platform/android/android_background_audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'system media metadata preserves Cyrillic fields without credentials',
    () {
      const track = RemoteTrack(
        path: 'Тест — Песня.flac',
        sizeBytes: 750000,
        title: 'Песня',
        artist: 'Исполнитель',
        album: 'Альбом',
        duration: Duration(minutes: 3, seconds: 15),
      );
      final item = mediaItemForTrack(track);
      expect(item.id, startsWith('track:'));
      expect(item.id, hasLength(70));
      expect(item.id, isNot(contains(track.path)));
      expect(item.id, isNot(contains('Песня.flac')));
      expect(item.id, mediaItemForTrack(track).id);
      const changedEtag = RemoteTrack(
        path: 'Тест — Песня.flac',
        sizeBytes: 750000,
        etag: 'changed',
        title: 'Песня',
        artist: 'Исполнитель',
      );
      expect(mediaItemForTrack(changedEtag).id, isNot(item.id));
      expect(item.title, 'Песня');
      expect(item.artist, 'Исполнитель');
      expect(item.album, 'Альбом');
      expect(item.duration, const Duration(minutes: 3, seconds: 15));
      expect(item.artUri, isNull);
    },
  );
}
