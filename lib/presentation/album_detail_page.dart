import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audio/playback_controller.dart';
import '../domain/album_track_order.dart';
import '../domain/remote_track.dart';
import '../l10n/app_localizations.dart';
import 'album_cover_thumbnail.dart';
import 'app_bottom_navigation_bar.dart';
import 'collection_summary.dart';
import 'mini_player.dart';

/// Album artwork, factual metadata and an uninterrupted album queue.
/// Album cards only navigate here; playback is always an explicit action.
class AlbumDetailPage extends ConsumerWidget {
  const AlbumDetailPage({required this.tracks, super.key});

  final List<RemoteTrack> tracks;

  String _duration(Duration? value) {
    if (value == null) return '';
    return '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final sorted = List<RemoteTrack>.of(tracks)..sort(compareAlbumTracks);
    if (sorted.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(strings.libraryEmpty)),
      );
    }

    final first = sorted.first;
    final summary = CollectionSummary.fromTracks(sorted);
    final playingPath = ref.watch(
      playbackControllerProvider.select((playback) => playback.track?.path),
    );
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final coverSize = math.min(width - 64, width >= 720 ? 300.0 : 280.0);

    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          if (width < 720) const AppBottomNavigationBar(returnToShell: true),
        ],
      ),
      body: CustomScrollView(
        key: const ValueKey('album-detail-scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.primary.withValues(alpha: 0.12),
                    colors.surface,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Column(
                  children: [
                    AlbumCoverThumbnail(
                      key: ValueKey('album-hero-${first.albumKey}'),
                      track: first,
                      size: coverSize,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      first.displayAlbum,
                      key: const ValueKey('album-detail-title'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (first.albumArtist?.trim().isNotEmpty ?? false)
                          ? first.albumArtist!
                          : first.displayArtist,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: colors.primary),
                    ),
                    const SizedBox(height: 12),
                    CollectionSummaryChips(summary: summary),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Tooltip(
                          message: strings.play,
                          child: SizedBox(
                            width: 128,
                            height: 48,
                            child: FilledButton(
                              key: const ValueKey('album-play-all'),
                              onPressed: () => ref
                                  .read(playbackControllerProvider.notifier)
                                  .playFromList(sorted, 0),
                              child: const Icon(Icons.play_arrow, size: 28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Tooltip(
                          message: strings.shuffleOn,
                          child: SizedBox(
                            width: 56,
                            height: 48,
                            child: OutlinedButton(
                              key: const ValueKey('album-shuffle'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () async {
                                final controller = ref.read(
                                  playbackControllerProvider.notifier,
                                );
                                await controller.playFromList(sorted, 0);
                                controller.setShuffle(true);
                              },
                              child: const Icon(Icons.shuffle),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                strings.tracks,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SliverList.builder(
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final track = sorted[index];
              final number = track.trackNumber ?? index + 1;
              final discChange =
                  track.discNumber != null &&
                  (index == 0 ||
                      track.discNumber != sorted[index - 1].discNumber);
              final playing = track.path == playingPath;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (discChange)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
                      child: Text(
                        strings.albumDiscNumber(track.discNumber!),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Material(
                      color: playing
                          ? colors.primary.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        key: ValueKey('album-track-${track.path}'),
                        minVerticalPadding: 6,
                        leading: SizedBox(
                          width: 32,
                          child: Center(
                            child: playing
                                ? Icon(
                                    Icons.equalizer_rounded,
                                    color: colors.primary,
                                  )
                                : Text('$number'),
                          ),
                        ),
                        title: Text(
                          track.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: playing
                              ? TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                )
                              : null,
                        ),
                        subtitle: track.displayArtist == first.displayArtist
                            ? null
                            : Text(
                                track.displayArtist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        trailing: Text(
                          _duration(track.duration),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onTap: () => ref
                            .read(playbackControllerProvider.notifier)
                            .playFromList(sorted, index),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
