import 'package:cloudmail_player/data/audio/playback_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('audio event lifecycle gate', () {
    test('accepts events only for an active settled source', () {
      expect(
        acceptsActiveAudioEvent(
          disposed: false,
          switchingTrack: false,
          hasQueue: true,
          hasTrack: true,
        ),
        isTrue,
      );
    });

    test('rejects old events while a new track is opening', () {
      expect(
        acceptsActiveAudioEvent(
          disposed: false,
          switchingTrack: true,
          hasQueue: true,
          hasTrack: true,
        ),
        isFalse,
      );
    });

    test('rejects delayed events after Stop clears queue', () {
      expect(
        acceptsActiveAudioEvent(
          disposed: false,
          switchingTrack: false,
          hasQueue: false,
          hasTrack: true,
        ),
        isFalse,
      );
    });

    test('rejects events with no current track or after disposal', () {
      expect(
        acceptsActiveAudioEvent(
          disposed: false,
          switchingTrack: false,
          hasQueue: true,
          hasTrack: false,
        ),
        isFalse,
      );
      expect(
        acceptsActiveAudioEvent(
          disposed: true,
          switchingTrack: false,
          hasQueue: true,
          hasTrack: true,
        ),
        isFalse,
      );
    });
  });
}
