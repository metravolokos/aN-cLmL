import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audio/playback_controller.dart';
import '../domain/track_queue.dart';
import '../l10n/app_localizations.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  String _time(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackControllerProvider);
    if (playback.track == null) return const SizedBox.shrink();
    final strings = AppLocalizations.of(context)!;
    final max = playback.duration.inMilliseconds;
    final position = playback.position.inMilliseconds.clamp(
      0,
      max > 0 ? max : 0,
    );
    return Material(
      elevation: 2,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (max > 0)
            Slider(
              value: position.toDouble(),
              min: 0,
              max: max.toDouble(),
              onChanged: (value) => ref
                  .read(playbackControllerProvider.notifier)
                  .seek(Duration(milliseconds: value.round())),
            )
          else if (playback.loading)
            const LinearProgressIndicator(),
          Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.music_note),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playback.track!.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      playback.failed
                          ? strings.playbackError
                          : playback.loading
                          ? strings.loadingAudio
                          : '${_time(playback.position)} / ${_time(playback.duration)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: strings.prev,
                icon: const Icon(Icons.skip_previous),
                onPressed: () =>
                    ref.read(playbackControllerProvider.notifier).previous(),
              ),
              IconButton(
                tooltip: playback.playing ? strings.pause : strings.play,
                icon: Icon(playback.playing ? Icons.pause : Icons.play_arrow),
                onPressed: () => ref
                    .read(playbackControllerProvider.notifier)
                    .pauseOrResume(),
              ),
              IconButton(
                tooltip: strings.next,
                icon: const Icon(Icons.skip_next),
                onPressed: () =>
                    ref.read(playbackControllerProvider.notifier).next(),
              ),
              IconButton(
                tooltip: 'Стоп',
                icon: const Icon(Icons.stop),
                onPressed: () =>
                    ref.read(playbackControllerProvider.notifier).stop(),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Перемешать',
                color: playback.shuffle
                    ? Theme.of(context).colorScheme.primary
                    : null,
                icon: const Icon(Icons.shuffle),
                onPressed: () => ref
                    .read(playbackControllerProvider.notifier)
                    .setShuffle(!playback.shuffle),
              ),
              IconButton(
                tooltip: 'Повтор',
                color: playback.repeat != QueueRepeat.off
                    ? Theme.of(context).colorScheme.primary
                    : null,
                icon: Icon(
                  playback.repeat == QueueRepeat.one
                      ? Icons.repeat_one
                      : Icons.repeat,
                ),
                onPressed: () {
                  final nextMode = switch (playback.repeat) {
                    QueueRepeat.off => QueueRepeat.all,
                    QueueRepeat.all => QueueRepeat.one,
                    QueueRepeat.one => QueueRepeat.off,
                  };
                  ref
                      .read(playbackControllerProvider.notifier)
                      .setRepeat(nextMode);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
