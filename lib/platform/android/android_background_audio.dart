import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/audio/playback_controller.dart';
import '../../domain/remote_track.dart';

CloudAndroidAudioHandler? _androidHandler;

/// Starts one Android OS MediaSession. Other OSes use their native backends.
Future<void> initializeAndroidPlaybackControls() async {
  if (!Platform.isAndroid) return;
  _androidHandler = await AudioService.init(
    builder: CloudAndroidAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.cloudmailplayer.cloudmail_player.audio',
      androidNotificationChannelName: 'Воспроизведение музыки',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false,
    ),
  );
}

/// Pure metadata conversion, with no credentials or authenticated URI.
MediaItem mediaItemForTrack(RemoteTrack track) => MediaItem(
  id: track.path,
  title: track.displayTitle,
  artist: track.displayArtist,
  album: track.displayAlbum,
  duration: track.duration,
);

Object? androidMediaTag(RemoteTrack track) {
  if (!Platform.isAndroid) return null;
  return mediaItemForTrack(track);
}

/// System media controls dispatch to the same Flutter playback controller
/// used by the on-screen mini-player and Now Playing screen.
class CloudAndroidAudioHandler extends BaseAudioHandler {
  PlaybackView _view = const PlaybackView();
  String? _mediaIdentity;

  Future<void> Function()? onPlay;
  Future<void> Function()? onPause;
  Future<void> Function()? onStop;
  Future<void> Function()? onNext;
  Future<void> Function()? onPrevious;
  Future<void> Function(Duration position)? onSeek;

  void synchronize(PlaybackView view) {
    _view = view;
    final track = view.track;
    final identity = track == null
        ? null
        : '${track.path}\u0000${track.etag ?? ''}\u0000${track.sizeBytes}';
    if (identity != _mediaIdentity) {
      _mediaIdentity = identity;
      mediaItem.add(track == null ? null : mediaItemForTrack(track));
      queue.add(track == null ? <MediaItem>[] : [mediaItemForTrack(track)]);
    }

    final available = track != null;
    playbackState.add(
      PlaybackState(
        controls: available
            ? [
                MediaControl.skipToPrevious,
                view.playing ? MediaControl.pause : MediaControl.play,
                MediaControl.skipToNext,
                MediaControl.stop,
              ]
            : <MediaControl>[],
        androidCompactActionIndices: available ? const [0, 1, 2] : const [],
        systemActions: available ? const {MediaAction.seek} : const {},
        processingState: !available
            ? AudioProcessingState.idle
            : view.failed
            ? AudioProcessingState.error
            : view.loading
            ? AudioProcessingState.buffering
            : AudioProcessingState.ready,
        playing: view.playing,
        updatePosition: view.position,
        speed: 1.0,
      ),
    );
  }

  @override
  Future<void> play() async {
    if (_view.track != null && !_view.playing) await onPlay?.call();
  }

  @override
  Future<void> pause() async {
    if (_view.playing) await onPause?.call();
  }

  @override
  Future<void> stop() async {
    await onStop?.call();
  }

  @override
  Future<void> skipToNext() async {
    await onNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    await onPrevious?.call();
  }

  @override
  Future<void> seek(Duration position) async {
    await onSeek?.call(position);
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    switch (button) {
      case MediaButton.next:
        await skipToNext();
        return;
      case MediaButton.previous:
        await skipToPrevious();
        return;
      case MediaButton.media:
        if (_view.playing) {
          await pause();
        } else {
          await play();
        }
        return;
    }
  }

  void unbind() {
    onPlay = null;
    onPause = null;
    onStop = null;
    onNext = null;
    onPrevious = null;
    onSeek = null;
  }
}

/// Binds OS commands to Riverpod without importing Android libraries into
/// shared domain/data/presentation code.
class AndroidMediaSessionBridge extends ConsumerStatefulWidget {
  const AndroidMediaSessionBridge({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AndroidMediaSessionBridge> createState() =>
      _AndroidMediaSessionBridgeState();
}

class _AndroidMediaSessionBridgeState
    extends ConsumerState<AndroidMediaSessionBridge> {
  @override
  void initState() {
    super.initState();
    final handler = _androidHandler;
    if (handler == null) return;
    final controller = ref.read(playbackControllerProvider.notifier);
    handler.onPlay = () async {
      if (!ref.read(playbackControllerProvider).playing) {
        await controller.pauseOrResume();
      }
    };
    handler.onPause = () async {
      if (ref.read(playbackControllerProvider).playing) {
        await controller.pauseOrResume();
      }
    };
    handler.onStop = controller.stop;
    handler.onNext = () => controller.next();
    handler.onPrevious = controller.previous;
    handler.onSeek = controller.seek;
    handler.synchronize(ref.read(playbackControllerProvider));
  }

  @override
  Widget build(BuildContext context) {
    final handler = _androidHandler;
    if (handler != null) {
      ref.listen<PlaybackView>(
        playbackControllerProvider,
        (previous, next) => handler.synchronize(next),
      );
    }
    return widget.child;
  }

  @override
  void dispose() {
    _androidHandler?.unbind();
    super.dispose();
  }
}
