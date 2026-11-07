import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/state.dart';
import '../data/audio/playback_controller.dart';
import '../data/library/cloud_music_service.dart';
import '../data/library/catalog_import_progress.dart';
import '../domain/remote_track.dart';
import '../domain/album_track_order.dart';
import '../domain/library_search.dart';
import '../l10n/app_localizations.dart';
import 'album_cover_thumbnail.dart';
import 'album_detail_page.dart';
import 'mini_player.dart';
import 'app_bottom_navigation_bar.dart';
import 'collection_summary.dart';

/// Displays the actual cloud catalog. Album/artist names are placeholders
/// until the bounded FLAC/ID3 tag scanner is enabled; no invented metadata.
class CloudLibraryPage extends ConsumerStatefulWidget {
  const CloudLibraryPage({required this.destination, super.key});

  final AppDestination destination;

  @override
  ConsumerState<CloudLibraryPage> createState() => _CloudLibraryPageState();
}

class _CloudLibraryPageState extends ConsumerState<CloudLibraryPage> {
  final Map<AppDestination, TextEditingController> _searchControllers = {};
  final Set<AppDestination> _expandedSearch = {};

  @override
  void dispose() {
    for (final controller in _searchControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _searchFor(AppDestination destination) =>
      _searchControllers.putIfAbsent(destination, TextEditingController.new);

  void _openAlbum(BuildContext context, List<RemoteTrack> tracks) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => AlbumDetailPage(tracks: tracks)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final tracksAsync = ref.watch(cloudCatalogProvider);
    final importProgress = ref.watch(catalogImportProgressProvider);
    final destination = widget.destination;
    final title = switch (destination) {
      AppDestination.home => strings.home,
      AppDestination.tracks => strings.tracks,
      AppDestination.albums => strings.albums,
      AppDestination.artists => strings.artists,
    };
    final tracks = switch (tracksAsync) {
      AsyncData<List<RemoteTrack>>(:final value) => value,
      _ => const <RemoteTrack>[],
    };
    final query = _searchFor(destination).text;
    final filtered = tracks
        .where((track) => matchesLibraryQuery(track, query))
        .toList();
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
                key: ValueKey('library-search-toggle-${destination.name}'),
                tooltip: strings.librarySearch,
                icon: Icon(
                  _expandedSearch.contains(destination)
                      ? Icons.close
                      : Icons.search,
                ),
                onPressed: () => setState(() {
                  if (!_expandedSearch.remove(destination)) {
                    _expandedSearch.add(destination);
                  } else {
                    _searchFor(destination).clear();
                  }
                }),
              ),
              IconButton(
                key: const ValueKey('refresh-library'),
                tooltip: strings.libraryRefresh,
                icon: const Icon(Icons.refresh),
                onPressed: importProgress.inProgress
                    ? null
                    : () => ref.read(cloudCatalogProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
        if (importProgress.inProgress || importProgress.failed)
          Padding(
            key: const ValueKey('library-import-progress'),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(switch (importProgress.phase) {
                    CatalogImportPhase.listing =>
                      strings.libraryReceiveProgress(
                        importProgress.receivedBytes ~/ 1024,
                      ),
                    CatalogImportPhase.metadata =>
                      strings.libraryMetadataProgress(
                        importProgress.done,
                        importProgress.total,
                      ),
                    CatalogImportPhase.failed =>
                      '${strings.libraryError} '
                          '[${importProgress.failureStage?.name ?? 'unknown'}/'
                          '${importProgress.failureCode?.name ?? 'unknown'}]',
                    _ => '',
                  }, key: const ValueKey('library-progress-label')),
                  const SizedBox(height: 6),
                  if (importProgress.inProgress)
                    LinearProgressIndicator(
                      value:
                          importProgress.phase == CatalogImportPhase.metadata &&
                              importProgress.total > 0
                          ? importProgress.done / importProgress.total
                          : null,
                    ),
                ],
              ),
            ),
          ),
        if (_expandedSearch.contains(destination))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              key: ValueKey('library-search-${destination.name}'),
              autofocus: true,
              controller: _searchFor(destination),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: strings.librarySearch,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  tooltip: strings.clearSearch,
                  icon: const Icon(Icons.clear),
                  onPressed: () =>
                      setState(() => _searchFor(destination).clear()),
                ),
              ),
              onChanged: (_) => setState(() {}),
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
                          Text(
                            importProgress.phase == CatalogImportPhase.finished
                                ? strings.libraryEmpty
                                : importProgress.failed
                                ? strings.libraryError
                                : strings.libraryDisconnected,
                          ),
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
                          onTap: () => _openAlbum(context, albumTracks),
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
                  key: const ValueKey('artist-list'),
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    final artist = keys[index];
                    final artistTracks = groups[artist]!;
                    return ListTile(
                      key: ValueKey('artist-open-$artist'),
                      leading: const Icon(Icons.person_outline),
                      title: Text(artist),
                      subtitle: Text('${artistTracks.length}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ArtistDetailPage(
                            artist: artist,
                            tracks: artistTracks,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) =>
                    TrackListRow(track: filtered[index], queue: filtered),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Artwork-first two-line row shared by the track and artist lists.
/// Keep the list lazy so only visible artwork is requested from WebDAV.
class TrackListRow extends ConsumerWidget {
  const TrackListRow({required this.track, required this.queue, super.key});

  final RemoteTrack track;
  final List<RemoteTrack> queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    void play() {
      ref
          .read(playbackControllerProvider.notifier)
          .playFromList(
            queue,
            queue.indexWhere((item) => item.path == track.path),
          );
    }

    return ListTile(
      key: ValueKey('track-row-${track.path}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      minVerticalPadding: 8,
      leading: AlbumCoverThumbnail(
        key: ValueKey('track-cover-${track.path}:${track.etag}'),
        track: track,
        size: 52,
      ),
      title: Text(
        track.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.displayArtist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      trailing: PopupMenuButton<String>(
        key: ValueKey('track-more-${track.path}'),
        tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
        icon: const Icon(Icons.more_vert),
        onSelected: (action) {
          if (action == 'play') {
            play();
          } else if (action == 'album') {
            final albumTracks = queue
                .where((candidate) => candidate.albumKey == track.albumKey)
                .toList();
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => AlbumDetailPage(tracks: albumTracks),
              ),
            );
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'play', child: Text(strings.play)),
          PopupMenuItem(value: 'album', child: Text(strings.albums)),
        ],
      ),
      onTap: play,
    );
  }
}

/// An artist's own cloud library: factual counts, album cards, and all tracks.
/// A real artist portrait or popularity ranking is not available in WebDAV tags.
class ArtistDetailPage extends ConsumerWidget {
  const ArtistDetailPage({
    required this.artist,
    required this.tracks,
    super.key,
  });

  final String artist;
  final List<RemoteTrack> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final albums = <String, List<RemoteTrack>>{};
    for (final track in tracks) {
      albums.putIfAbsent(track.albumKey, () => <RemoteTrack>[]).add(track);
    }
    for (final group in albums.values) {
      group.sort(compareAlbumTracks);
    }
    final albumGroups = albums.values.toList()
      ..sort((a, b) => a.first.displayAlbum.compareTo(b.first.displayAlbum));
    final allTracks = <RemoteTrack>[for (final group in albumGroups) ...group];
    final summary = CollectionSummary.fromTracks(allTracks);

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
        key: const ValueKey('artist-detail-scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.primary.withValues(alpha: 0.15),
                    colors.surface,
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: Column(
                children: [
                  if (albumGroups.isNotEmpty)
                    AlbumCoverThumbnail(
                      key: ValueKey(
                        'artist-hero-${albumGroups.first.first.path}',
                      ),
                      track: albumGroups.first.first,
                      size: width >= 720 ? 260 : 224,
                    )
                  else
                    const Icon(Icons.person_outline, size: 120),
                  const SizedBox(height: 20),
                  Text(
                    artist,
                    key: const ValueKey('artist-detail-title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 14),
                  CollectionSummaryChips(
                    summary: summary,
                    albumCount: albumGroups.length,
                  ),
                  const SizedBox(height: 16),
                  if (allTracks.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Tooltip(
                          message: strings.play,
                          child: SizedBox(
                            width: 128,
                            height: 48,
                            child: FilledButton(
                              key: const ValueKey('artist-play-all'),
                              onPressed: () => ref
                                  .read(playbackControllerProvider.notifier)
                                  .playFromList(allTracks, 0),
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
                              key: const ValueKey('artist-shuffle'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () async {
                                final controller = ref.read(
                                  playbackControllerProvider.notifier,
                                );
                                await controller.playFromList(allTracks, 0);
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            sliver: SliverToBoxAdapter(
              child: Text(
                strings.albums,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid.builder(
              key: const ValueKey('artist-album-grid'),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 210,
                childAspectRatio: 0.79,
                mainAxisSpacing: 14,
                crossAxisSpacing: 12,
              ),
              itemCount: albumGroups.length,
              itemBuilder: (context, index) {
                final albumTracks = albumGroups[index];
                final first = albumTracks.first;
                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('artist-album-${first.albumKey}'),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => AlbumDetailPage(tracks: albumTracks),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: LayoutBuilder(
                            builder: (context, constraints) =>
                                AlbumCoverThumbnail(
                                  key: ValueKey(
                                    'artist-album-cover-${first.path}',
                                  ),
                                  track: first,
                                  size: constraints.maxWidth,
                                ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 7, 8, 0),
                          child: Text(
                            first.displayAlbum,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            strings.collectionTracksCount(albumTracks.length),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                strings.tracks,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SliverList.builder(
            itemCount: allTracks.length,
            itemBuilder: (context, index) =>
                TrackListRow(track: allTracks[index], queue: allTracks),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
