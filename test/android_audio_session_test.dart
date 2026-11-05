import 'package:audio_session/audio_session.dart';
import 'package:cloudmail_player/platform/android/android_audio_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android music session requests media usage and permanent audio focus', () {
    final config = musicAudioSessionConfiguration();
    expect(config.androidAudioAttributes?.usage, AndroidAudioUsage.media);
    expect(
      config.androidAudioAttributes?.contentType,
      AndroidAudioContentType.music,
    );
    expect(
      config.androidAudioFocusGainType,
      AndroidAudioFocusGainType.gain,
    );
  });
}
