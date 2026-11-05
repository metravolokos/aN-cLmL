import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../domain/remote_track.dart';

/// Android-only media session startup. Desktop audio remains on media_kit.
Future<void> initializeAndroidPlaybackControls() async {
  if (!Platform.isAndroid) return;
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.cloudmailplayer.cloudmail_player.audio',
    androidNotificationChannelName: 'Воспроизведение музыки',
    androidNotificationOngoing: true,
  );
}

/// A MediaItem is attached only to Android sources. Never put Basic Auth or
/// the Cloud.Mail.ru application password into media metadata or public URIs.
Object? androidMediaTag(RemoteTrack track) {
  if (!Platform.isAndroid) return null;
  return MediaItem(
    id: track.path,
    title: track.displayTitle,
    artist: track.displayArtist,
    album: track.displayAlbum,
    duration: track.duration,
  );
}
