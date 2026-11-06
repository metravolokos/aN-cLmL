import 'package:audio_service/audio_service.dart';
import 'package:cloudmail_player/data/audio/playback_controller.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/platform/android/android_background_audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'system media controls dispatch next, previous and headset actions',
    () async {
      final handler = CloudAndroidAudioHandler();
      var nextCalls = 0;
      var previousCalls = 0;
      var playCalls = 0;
      handler.onNext = () async {
        nextCalls++;
      };
      handler.onPrevious = () async {
        previousCalls++;
      };
      handler.onPlay = () async {
        playCalls++;
      };
      handler.synchronize(
        const PlaybackView(
          track: RemoteTrack(
            path: 'Песня.flac',
            sizeBytes: 10000,
            title: 'Песня',
            artist: 'Исполнитель',
          ),
        ),
      );
      final actions = handler.playbackState.value.controls.map(
        (control) => control.action,
      );
      expect(actions, contains(MediaAction.skipToNext));
      expect(actions, contains(MediaAction.skipToPrevious));
      expect(actions, contains(MediaAction.play));

      await handler.skipToNext();
      await handler.skipToPrevious();
      await handler.click(MediaButton.next);
      await handler.play();
      expect(nextCalls, 2);
      expect(previousCalls, 1);
      expect(playCalls, 1);
      expect(handler.mediaItem.value?.title, 'Песня');
      handler.unbind();
    },
  );
}
