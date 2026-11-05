import 'dart:io';

import 'package:audio_session/audio_session.dart';

/// Configure Android's system audio focus and media usage before playback.
/// just_audio owns interruption/noisy-device handling to avoid duplicate
/// pause/resume events from separate listeners.
Future<void> configureAndroidMusicAudioSession() async {
  if (!Platform.isAndroid) return;
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
}
