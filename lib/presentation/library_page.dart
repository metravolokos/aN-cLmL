import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/state.dart';
import '../data/audio/playback_controller.dart';
import '../data/library/cloud_music_service.dart';
import '../domain/remote_track.dart';
import '../domain/album_track_order.dart';
import '../l10n/app_localizations.dart';
import 'album_cover_thumbnail.dart';

/// Displays the actual cloud catalog. Album/artist names are placeholders
/// until the bounded FLAC/ID3 tag scanner is enabled; no invented metadata.
class CloudLibraryPage extends ConsumerStatefulWidget {
  const CloudLibraryPage({required this.destination, super.key});

  final AppDestination destination;

  @override
  ConsumerState<CloudLibraryPage> createState() => _CloudLibraryPageState();
}

class _CloudLibraryPageState extends ConsumerState<CloudLibraryPage> {
  String _filter = '';

  Future<void> _showAlbumTracks(
    BuildContext context,
    List<RemoteTrack> albumTracks,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  albumTracks.first.displayAlbum,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: albumTracks.length,
                  itemBuilder: (context, index) =>
                      _TrackTile(track: albumTracks[index], queue: albumTracks),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final tracksAsync = ref.watch(cloudCatalogProvider);
    final destination = widget.destination;
    final title = switch (destination) {
      AppDestination.tracks => strings.tracks,
      AppDestination.albums => strings.albums,
      AppDestination.artists => strings.artists,
      AppDestination.settings => strings.settings,
    };
    final tracks = switch (tracksAsync) {
      AsyncData<List<RemoteTrack>>(:final value) => value,
      _ => const <RemoteTrack>[],
    };
    final query = _filter.trim().toLowerCase();
    final filtered = tracks.where((track) {
      if (query.isEmpty) return true;
      return track.displayTitle.toLowerCase().contains(query) ||
          track.displayArtist.toLowerCase().contains(query) ||
          track.displayAlbum.toLowerCase().contains(query);
    }).toList();
    final groups = <String, List<RemoteTrack>>{};
    if (destination == AppDestination.albums ||
        destination == AppDestination.artists) {
      for (final track in filtered) {
        final key = destination == AppDestination.albums
            ? track.albumKey
            : track.displayArtist;
        groups.putIfAbsent(key, () => []).add(track);
      }
      if (destination == AppDestination.albums) {
        for (final group in groups.values) {
          group.sort(compareAlbumTracks);
        }
      }
    }
    return Column(
      key: ValueKey('page-${destination.name}'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                key: const ValueKey('refresh-library'),
                tooltip: strings.libraryRefresh,
                icon: const Icon(Icons.refresh),
                onPressed: tracksAsync.isLoading
                    ? null
                    : () => ref.read(cloudCatalogProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
        if (tracks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: strings.librarySearch,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _filter = value),
            ),
          ),
        if (tracks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(strings.libraryLoaded(tracks.length)),
          ),
        Expanded(
          child: tracksAsync.when(
            loading: () => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(strings.libraryLoading),
                ],
              ),
            ),
            error: (_, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.libraryError),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () =>
                        ref.read(cloudCatalogProvider.notifier).refresh(),
                    child: Text(strings.libraryRefresh),
                  ),
                ],
              ),
            ),
            data: (_) {
              if (tracks.isEmpty) {
                return ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 48),
                          const SizedBox(height: 10),
                          Text(strings.libraryDisconnected),
                          const SizedBox(height: 10),
                          Text(strings.libraryHint),
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const ValueKey('load-library'),
                            onPressed: () => ref
                                .read(cloudCatalogProvider.notifier)
                                .refresh(),
                            child: Text(strings.libraryRefresh),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              if (groups.isNotEmpty) {
                final keys = groups.keys.toList()..sort();
                if (destination == AppDestination.albums) {
                  return GridView.builder(
                    key: const ValueKey('album-grid'),
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 0.74,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: keys.length,
                    itemBuilder: (context, index) {
                      final albumTracks = groups[keys[index]]!;
                      final first = albumTracks.first;
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey('album-open-${first.albumKey}'),
                          onTap: () => _showAlbumTracks(context, albumTracks),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: LayoutBuilder(
                                  builder: (context, constraints) =>
                                      AlbumCoverThumbnail(
                                        key: ValueKey(
                                          '${first.path}:${first.etag}',
                                        ),
                                        track: first,
                                        size: constraints.maxWidth,
                                      ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      first.displayAlbum,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    Text(
                                      '${first.displayArtist} · ${albumTracks.length}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return ListView.builder(
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    return ExpansionTile(
                      title: Text(key),
                      subtitle: Text('${groups[key]!.length}'),
                      children: [
                        for (final track in groups[key]!)
                          _TrackTile(track: track, queue: groups[key]!),
                      ],
                    );
                  },
                );
              }
              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) =>
                    _TrackTile(track: filtered[index], queue: filtered),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TrackTile extends ConsumerWidget {
  const _TrackTile({required this.track, required this.queue});
  final RemoteTrack track;
  final List<RemoteTrack> queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.audiotrack),
      title: Text(
        track.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.play_arrow),
      onTap: () => ref
          .read(playbackControllerProvider.notifier)
          .playFromList(
            queue,
            queue.indexWhere((item) => item.path == track.path),
          ),
    );
  }
}
