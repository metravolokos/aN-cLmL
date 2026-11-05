import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/remote_track.dart';
import '../library/cloud_music_service.dart';
import 'cloud_range_audio_source.dart';

class PlaybackView {
  const PlaybackView({
    this.track,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.loading = false,
    this.failed = false,
  });

  final RemoteTrack? track;
  final Duration position;
  final Duration duration;
  final bool playing;
  final bool loading;
  final bool failed;

  PlaybackView withUpdates({
    RemoteTrack? track,
    Duration? position,
    Duration? duration,
    bool? playing,
    bool? loading,
    bool? failed,
  }) => PlaybackView(
    track: track ?? this.track,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    playing: playing ?? this.playing,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
  );
}

class PlaybackController extends Notifier<PlaybackView> {
  AudioPlayer? _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _closed = false;

  @override
  PlaybackView build() {
    ref.onDispose(() {
      _closed = true;
      for (final subscription in _subscriptions) {
        unawaited(subscription.cancel());
      }
      final player = _player;
      if (player != null) unawaited(player.dispose());
    });
    return const PlaybackView();
  }

  AudioPlayer _ensurePlayer() {
    if (_player != null) return _player!;
    final audio = AudioPlayer();
    _subscriptions.add(
      audio.positionStream.listen((position) {
        if (!_closed) state = state.withUpdates(position: position);
      }),
    );
    _subscriptions.add(
      audio.durationStream.listen((duration) {
        if (!_closed && duration != null) {
          state = state.withUpdates(duration: duration);
        }
      }),
    );
    _subscriptions.add(
      audio.playingStream.listen((playing) {
        if (!_closed) state = state.withUpdates(playing: playing);
      }),
    );
    _subscriptions.add(
      audio.processingStateStream.listen((processing) {
        if (!_closed) {
          state = state.withUpdates(
            loading:
                processing == ProcessingState.loading ||
                processing == ProcessingState.buffering,
          );
        }
      }),
    );
    _subscriptions.add(
      audio.errorStream.listen((_) {
        if (!_closed) state = state.withUpdates(failed: true, loading: false);
      }),
    );
    return _player = audio;
  }

  Future<void> playTrack(RemoteTrack track) async {
    state = PlaybackView(track: track, loading: true);
    try {
      final reader = ref.read(cloudMusicServiceProvider);
      final player = _ensurePlayer();
      await player.setAudioSource(
        CloudRangeAudioSource(track, reader.readRange),
      );
      unawaited(player.play());
    } catch (_) {
      state = state.withUpdates(failed: true, loading: false);
    }
  }

  Future<void> pauseOrResume() async {
    final player = _player;
    if (player == null) return;
    if (player.playing) {
      await player.pause();
    } else {
      unawaited(player.play());
    }
  }

  Future<void> seek(Duration position) async {
    await _player?.seek(position);
  }

  Future<void> stop() async {
    await _player?.stop();
    state = const PlaybackView();
  }
}

final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackView>(PlaybackController.new);
