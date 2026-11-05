import 'dart:io';

import 'package:just_audio_background/just_audio_background.dart';

/// Android-only media session startup. Desktop audio remains on media_kit.
Future<void> initializeAndroidPlaybackControls() async {
  if (!Platform.isAndroid) return;
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.cloudmailplayer.cloudmail_player.audio',
    androidNotificationChannelName: 'Воспроизведение музыки',
    androidNotificationOngoing: true,
  );
}
