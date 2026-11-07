import 'package:flutter/material.dart';

import '../domain/remote_track.dart';
import '../l10n/app_localizations.dart';

/// Album and artist facts derived only from indexed tags and file extensions.
class CollectionSummary {
  const CollectionSummary({
    required this.trackCount,
    required this.formats,
    required this.totalDuration,
  });

  final int trackCount;
  final List<String> formats;

  /// Unknown unless every track has an indexed, positive duration.
  /// Showing a partial sum as the collection total would be misleading.
  final Duration? totalDuration;

  factory CollectionSummary.fromTracks(Iterable<RemoteTrack> source) {
    final tracks = source.toList();
    var complete = tracks.isNotEmpty;
    var milliseconds = 0;
    final extensions = <String>{};
    for (final track in tracks) {
      final duration = track.duration;
      if (duration == null || duration <= Duration.zero) {
        complete = false;
      } else {
        milliseconds += duration.inMilliseconds;
      }
      final filename = track.fileName;
      final dot = filename.lastIndexOf('.');
      if (dot > 0 && dot < filename.length - 1) {
        extensions.add(filename.substring(dot + 1).toUpperCase());
      }
    }
    final formats = extensions.toList()..sort();
    return CollectionSummary(
      trackCount: tracks.length,
      formats: formats,
      totalDuration: complete ? Duration(milliseconds: milliseconds) : null,
    );
  }
}

/// Compact metadata in the same visual hierarchy on album and artist pages.
class CollectionSummaryChips extends StatelessWidget {
  const CollectionSummaryChips({
    required this.summary,
    this.albumCount,
    super.key,
  });

  final CollectionSummary summary;
  final int? albumCount;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final duration = summary.totalDuration;
    final durationLabel = duration == null
        ? null
        : duration.inHours > 0
        ? strings.collectionDurationHoursMinutes(
            duration.inHours,
            duration.inMinutes % 60,
          )
        : strings.collectionDurationMinutes(duration.inMinutes);

    Widget chip(IconData icon, String label) => Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Wrap(
      key: const ValueKey('collection-summary-chips'),
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        if (albumCount != null)
          chip(
            Icons.album_outlined,
            strings.collectionAlbumsCount(albumCount!),
          ),
        chip(
          Icons.music_note_outlined,
          strings.collectionTracksCount(summary.trackCount),
        ),
        if (durationLabel != null) chip(Icons.schedule_outlined, durationLabel),
        for (final format in summary.formats)
          Chip(
            label: Text(format),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}
