import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audio/playback_controller.dart';
import '../domain/album_track_order.dart';
import '../domain/remote_track.dart';
import '../l10n/app_localizations.dart';
import 'album_cover_thumbnail.dart';
import 'collection_summary.dart';

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
      return Scaffold(body: Center(child: Text(strings.libraryEmpty)));
    }

    final first = sorted.first;
    final summary = CollectionSummary.fromTracks(sorted);
    final playingPath = ref.watch(
      playbackControllerProvider.select((playback) => playback.track?.path),
    );
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final coverSize = math.min(width - 88, width >= 720 ? 280.0 : 238.0);

    return Scaffold(
      body: CustomScrollView(
        key: const ValueKey('album-detail-scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.16,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: AlbumCoverThumbnail(
                        key: ValueKey('album-atmosphere-${first.albumKey}'),
                        track: first,
                        size: math.max(width, 420.0),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.primaryContainer.withValues(alpha: 0.34),
                          colors.surface.withValues(alpha: 0.66),
                          colors.surface,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                  child: Column(
                    children: [
                      AlbumCoverThumbnail(
                        key: ValueKey('album-hero-${first.albumKey}'),
                        track: first,
                        size: coverSize,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        first.displayAlbum,
                        key: const ValueKey('album-detail-title'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (first.albumArtist?.trim().isNotEmpty ?? false)
                            ? first.albumArtist!
                            : first.displayArtist,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colors.primary),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Tooltip(
                            message: strings.play,
                            child: SizedBox(
                              width: 184,
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
                              width: 60,
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
                      const SizedBox(height: 16),
                      CollectionSummaryChips(summary: summary),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton.filledTonal(
                    key: const ValueKey('album-detail-back'),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 6)),
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
                        dense: true,
                        minVerticalPadding: 2,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
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
