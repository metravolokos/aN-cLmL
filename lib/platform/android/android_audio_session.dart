import 'dart:io';

import 'package:audio_session/audio_session.dart';

AudioSessionConfiguration musicAudioSessionConfiguration() =>
    const AudioSessionConfiguration.music();

/// Configure Android's system audio focus and media usage before playback.
/// just_audio owns interruption/noisy-device handling to avoid duplicate
/// pause/resume events from separate listeners.
Future<void> configureAndroidMusicAudioSession() async {
  if (!Platform.isAndroid) return;
  try {
    final session = await AudioSession.instance;
    await session.configure(musicAudioSessionConfiguration());
  } catch (_) {
    // A device without a usable audio-session channel should still launch.
    // just_audio retains its own default music-session behavior.
  }
}
