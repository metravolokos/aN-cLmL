import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audio/playback_controller.dart';
import '../data/library/cloud_music_service.dart';
import '../domain/remote_track.dart';
import '../domain/track_queue.dart';
import '../l10n/app_localizations.dart';

/// One playback session, shared with the persistent mini-player.
class NowPlayingPage extends ConsumerWidget {
  const NowPlayingPage({super.key});

  String _formatTime(Duration value) {
    final minutes = value.inMinutes;
    final suffix = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$suffix';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackControllerProvider);
    final labels = AppLocalizations.of(context)!;
    final track = playback.track;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(labels.nowPlaying)),
      body: track == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.music_off, size: 64, color: colors.outline),
                  const SizedBox(height: 16),
                  Text(labels.noTrackPlaying),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final available = constraints.maxWidth - 48;
                final size = available < 0
                    ? 0.0
                    : (available > 360 ? 360.0 : available);
                final totalMs = playback.duration.inMilliseconds;
                final positionMs = playback.position.inMilliseconds.clamp(
                  0,
                  totalMs > 0 ? totalMs : 0,
                );
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Container(
                              width: size,
                              height: size,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: _TrackArtwork(
                                key: ValueKey(
                                  '${track.path}:${track.etag}:${track.sizeBytes}',
                                ),
                                track: track,
                                size: size,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            track.displayTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            track.displayArtist,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.displayAlbum,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 18),
                          if (playback.failed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                labels.playbackError,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: colors.error),
                              ),
                            ),
                          if (playback.loading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: LinearProgressIndicator(),
                            ),
                          Slider(
                            value: positionMs.toDouble(),
                            min: 0,
                            max: totalMs > 0 ? totalMs.toDouble() : 1.0,
                            onChanged: totalMs > 0
                                ? (value) => ref
                                      .read(playbackControllerProvider.notifier)
                                      .seek(
                                        Duration(milliseconds: value.round()),
                                      )
                                : null,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatTime(playback.position)),
                              Text(_formatTime(playback.duration)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                tooltip: playback.shuffled
                                    ? labels.shuffleOn
                                    : labels.shuffleOff,
                                icon: Icon(
                                  playback.shuffled
                                      ? Icons.shuffle_on_outlined
                                      : Icons.shuffle,
                                ),
                                color: playback.shuffled
                                    ? colors.primary
                                    : null,
                                onPressed: () => ref
                                    .read(playbackControllerProvider.notifier)
                                    .setShuffle(!playback.shuffled),
                              ),
                              IconButton(
                                tooltip: labels.prev,
                                icon: const Icon(Icons.skip_previous),
                                iconSize: 36,
                                onPressed: () => ref
                                    .read(playbackControllerProvider.notifier)
                                    .previous(),
                              ),
                              IconButton.filled(
                                tooltip: playback.playing
                                    ? labels.pause
                                    : labels.play,
                                icon: Icon(
                                  playback.playing
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                                iconSize: 36,
                                onPressed: () => ref
                                    .read(playbackControllerProvider.notifier)
                                    .pauseOrResume(),
                              ),
                              IconButton(
                                tooltip: labels.next,
                                icon: const Icon(Icons.skip_next),
                                iconSize: 36,
                                onPressed: () => ref
                                    .read(playbackControllerProvider.notifier)
                                    .next(),
                              ),
                              IconButton(
                                tooltip: switch (playback.repeatMode) {
                                  PlayerRepeatMode.off => labels.repeatOff,
                                  PlayerRepeatMode.all => labels.repeatAll,
                                  PlayerRepeatMode.one => labels.repeatOne,
                                },
                                icon: Icon(
                                  playback.repeatMode == PlayerRepeatMode.one
                                      ? Icons.repeat_one
                                      : Icons.repeat,
                                ),
                                color:
                                    playback.repeatMode != PlayerRepeatMode.off
                                    ? colors.primary
                                    : null,
                                onPressed: () => ref
                                    .read(playbackControllerProvider.notifier)
                                    .cycleRepeat(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _TrackArtwork extends ConsumerStatefulWidget {
  const _TrackArtwork({required this.track, required this.size, super.key});

  final RemoteTrack track;
  final double size;

  @override
  ConsumerState<_TrackArtwork> createState() => _TrackArtworkState();
}

class _TrackArtworkState extends ConsumerState<_TrackArtwork> {
  late final Future<Uint8List?> _image;

  @override
  void initState() {
    super.initState();
    _image = ref
        .read(cloudMusicServiceProvider)
        .readArtwork(widget.track)
        .catchError((Object _, StackTrace __) => null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget placeholder() => Icon(
      Icons.album,
      size: widget.size / 2,
      color: colors.onSurfaceVariant,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: FutureBuilder<Uint8List?>(
        future: _image,
        builder: (context, snapshot) {
          final image = snapshot.data;
          if (image == null || image.isEmpty) return placeholder();
          return Image.memory(
            image,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            cacheWidth: 800,
            cacheHeight: 800,
            errorBuilder: (context, error, stackTrace) => placeholder(),
          );
        },
      ),
    );
  }
}
