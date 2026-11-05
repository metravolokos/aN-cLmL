import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../cloud/cloud_mail_webdav.dart';
import '../../domain/remote_track.dart';
import '../../domain/track_queue.dart';
import '../library/cloud_music_service.dart';
import 'cloud_range_audio_source.dart';
import 'two_track_cache.dart';

class PlaybackView {
  const PlaybackView({
    this.track,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.loading = false,
    this.failed = false,
    this.shuffled = false,
    this.repeatMode = PlayerRepeatMode.off,
  });

  final RemoteTrack? track;
  final Duration position;
  final Duration duration;
  final bool playing;
  final bool loading;
  final bool failed;
  final bool shuffled;
  final PlayerRepeatMode repeatMode;

  PlaybackView withUpdates({
    RemoteTrack? track,
    Duration? position,
    Duration? duration,
    bool? playing,
    bool? loading,
    bool? failed,
    bool? shuffled,
    PlayerRepeatMode? repeatMode,
  }) => PlaybackView(
    track: track ?? this.track,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    playing: playing ?? this.playing,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    shuffled: shuffled ?? this.shuffled,
    repeatMode: repeatMode ?? this.repeatMode,
  );
}

class PlaybackController extends Notifier<PlaybackView> {
  AudioPlayer? _player;
  Future<TwoTrackAudioCache>? _cacheFuture;
  TrackQueue? _queue;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _closed = false;
  bool _changingTrack = false;

  @override
  PlaybackView build() {
    ref.onDispose(() {
      _closed = true;
      for (final subscription in _subscriptions) {
        unawaited(subscription.cancel());
      }
      final player = _player;
      if (player != null) unawaited(player.dispose());
      final cacheFuture = _cacheFuture;
      if (cacheFuture != null) {
        unawaited(cacheFuture.then((cache) => cache.close()).onError(
          (Object _, StackTrace __) {},
        ));
      }
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
        if (_closed) return;
        state = state.withUpdates(
          loading:
              processing == ProcessingState.loading ||
              processing == ProcessingState.buffering,
        );
        if (processing == ProcessingState.completed && !_changingTrack) {
          unawaited(next(manual: false));
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

  Future<void> _open(RemoteTrack track) async {
    if (_closed || _changingTrack) return;
    _changingTrack = true;
    state = PlaybackView(
      track: track,
      loading: true,
      shuffled: _queue?.shuffled ?? false,
      repeatMode: _queue?.repeatMode ?? PlayerRepeatMode.off,
    );
    try {
      final reader = ref.read(cloudMusicServiceProvider);
      TwoTrackAudioCache? activeCache;
      try {
        _cacheFuture ??= TwoTrackAudioCache.open(
          fetch: (
            String path,
            int offset,
            int length, {
            WebDavRequestCancellation? cancellation,
          }) => reader.readRange(
            path,
            offset,
            length,
            cancellation: cancellation,
          ),
        );
        activeCache = await _cacheFuture;
        await activeCache.configure(track, _queue?.nextForPrefetch());
      } catch (_) {
        // A read-only cache is an optimization; playback can stream directly.
        final abandoned = _cacheFuture;
        _cacheFuture = null;
        if (abandoned != null) {
          unawaited(abandoned.then((cache) => cache.close()).onError(
            (Object _, StackTrace __) {},
          ));
        }
        activeCache = null;
      }
      final cache = activeCache;
      final player = _ensurePlayer();
      await player.setAudioSource(
        CloudRangeAudioSource(
          track,
          cache == null
              ? reader.readRange
              : (path, offset, length) => cache.read(path, offset, length),
        ),
      );
      if (!_closed) unawaited(player.play());
    } catch (_) {
      if (!_closed) state = state.withUpdates(failed: true, loading: false);
    } finally {
      _changingTrack = false;
    }
  }

  Future<void> playFromList(List<RemoteTrack> tracks, int index) async {
    if (tracks.isEmpty || index < 0 || index >= tracks.length) return;
    _queue = TrackQueue(tracks, index);
    await _open(_queue!.current);
  }

  Future<void> playTrack(RemoteTrack track) async {
    await playFromList([track], 0);
  }

  Future<void> next({bool manual = true}) async {
    if (_changingTrack || _closed) return;
    final newTrack = _queue?.next(manual: manual);
    if (newTrack != null) {
      await _open(newTrack);
    } else if (!manual) {
      await stop();
    }
  }

  Future<void> previous() async {
    if (_changingTrack || _closed) return;
    final newTrack = _queue?.previous();
    if (newTrack != null) {
      await _open(newTrack);
    } else {
      await seek(Duration.zero);
    }
  }

  void setShuffle(bool enabled) {
    _queue?.setShuffled(enabled);
    state = state.withUpdates(shuffled: _queue?.shuffled ?? enabled);
  }

  void cycleRepeat() {
    final repeatMode = _queue?.cycleRepeat() ?? PlayerRepeatMode.off;
    state = state.withUpdates(repeatMode: repeatMode);
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

  Future<void> seek(Duration position) async => _player?.seek(position);

  Future<void> stop() async {
    await _player?.stop();
    _queue = null;
    final cacheFuture = _cacheFuture;
    _cacheFuture = null;
    if (cacheFuture != null) {
      try {
        await (await cacheFuture).close();
      } catch (_) {
        // Stopping playback must succeed even when temporary storage fails.
      }
    }
    state = const PlaybackView();
  }
}

final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackView>(PlaybackController.new);
