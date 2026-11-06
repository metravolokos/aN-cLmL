import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audio/playback_controller.dart';
import '../l10n/app_localizations.dart';
import 'now_playing_page.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});


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
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const NowPlayingPage(),
                      ),
                    );
                  },
                  child: Text(
                    playback.failed
                        ? strings.playbackError
                        : playback.track!.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                tooltip: playback.playing ? strings.pause : strings.play,
                icon: Icon(playback.playing ? Icons.pause : Icons.play_arrow),
                onPressed: () => ref
                    .read(playbackControllerProvider.notifier)
                    .pauseOrResume(),
              ),
              IconButton(
                tooltip: strings.prev,
                icon: const Icon(Icons.skip_previous),
                onPressed: () =>
                    ref.read(playbackControllerProvider.notifier).previous(),
              ),
              IconButton(
                tooltip: strings.next,
                icon: const Icon(Icons.skip_next),
                onPressed: () =>
                    ref.read(playbackControllerProvider.notifier).next(),
              ),
              const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
