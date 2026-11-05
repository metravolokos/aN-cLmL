import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/library/cloud_music_service.dart';
import '../domain/remote_track.dart';

/// Small lazy album-cover thumbnail. The CloudMusicService shares only the
/// last three decoded source byte buffers across visible widgets.
class AlbumCoverThumbnail extends ConsumerStatefulWidget {
  const AlbumCoverThumbnail({required this.track, super.key});

  final RemoteTrack track;

  @override
  ConsumerState<AlbumCoverThumbnail> createState() =>
      _AlbumCoverThumbnailState();
}

class _AlbumCoverThumbnailState extends ConsumerState<AlbumCoverThumbnail> {
  late final Future<Uint8List?> imageFuture;

  @override
  void initState() {
    super.initState();
    imageFuture = ref
        .read(cloudMusicServiceProvider)
        .readArtwork(widget.track)
        .catchError((Object error, StackTrace stackTrace) => null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget placeholder() => Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.album_outlined, color: colors.onSurfaceVariant),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: FutureBuilder<Uint8List?>(
        future: imageFuture,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) return placeholder();
          return Image.memory(
            bytes,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            cacheWidth: 104,
            cacheHeight: 104,
            errorBuilder: (context, error, stackTrace) => placeholder(),
          );
        },
      ),
    );
  }
}
