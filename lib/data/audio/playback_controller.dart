import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/remote_track.dart';
import '../../domain/track_queue.dart';
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
    this.shuffle = false,
    this.repeat = QueueRepeat.off,
  });

  final RemoteTrack? track;
  final Duration position;
  final Duration duration;
  final bool playing;
  final bool loading;
  final bool failed;
  final bool shuffle;
  final QueueRepeat repeat;

  PlaybackView withUpdates({
    RemoteTrack? track,
    Duration? position,
    Duration? duration,
    bool? playing,
    bool? loading,
    bool? failed,
    bool? shuffle,
    QueueRepeat? repeat,
  }) => PlaybackView(
    track: track ?? this.track,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    playing: playing ?? this.playing,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    shuffle: shuffle ?? this.shuffle,
    repeat: repeat ?? this.repeat,
  );
}

class PlaybackController extends Notifier<PlaybackView> {
  AudioPlayer? _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _closed = false;
  final TrackQueue _queue = TrackQueue();

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
        if (!_closed && processing == ProcessingState.completed) {
          unawaited(next(automatic: true));
        }
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

  Future<void> playTrack(RemoteTrack track) =>
      playFromQueue([track]);

  Future<void> playFromQueue(
    List<RemoteTrack> tracks, {
    int startIndex = 0,
  }) async {
    _queue.load(tracks, startIndex: startIndex);
    final track = _queue.current;
    if (track != null) await _playCurrent(track);
  }

  Future<void> _playCurrent(RemoteTrack track) async {
    state = PlaybackView(
      track: track,
      loading: true,
      shuffle: _queue.shuffle,
      repeat: _queue.repeat,
    );
    try {
      final reader = ref.read(cloudMusicServiceProvider);
      final player = _ensurePlayer();
      await player.setAudioSource(
        CloudRangeAudioSource(track, reader.readRange),
      );
      if (!_closed) unawaited(player.play());
    } catch (_) {
      if (!_closed) {
        state = state.withUpdates(failed: true, loading: false);
      }
    }
  }

  Future<void> next({bool automatic = false}) async {
    final track = _queue.next(automatic: automatic);
    if (track == null) {
      if (automatic) await _player?.stop();
      return;
    }
    await _playCurrent(track);
  }

  Future<void> previous() async {
    final track = _queue.previous();
    if (track != null) await _playCurrent(track);
  }

  void setShuffle(bool enabled) {
    _queue.setShuffle(enabled);
    state = state.withUpdates(shuffle: enabled);
  }

  void setRepeat(QueueRepeat mode) {
    _queue.setRepeat(mode);
    state = state.withUpdates(repeat: mode);
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
    _queue.clear();
    state = PlaybackView(shuffle: _queue.shuffle, repeat: _queue.repeat);
  }
}

final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackView>(PlaybackController.new);
