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

    // Present facts as one quiet caption line rather than a group of
    // prominent Material chips competing with the cover and album title.
    final facts = <String>[
      if (albumCount != null) strings.collectionAlbumsCount(albumCount!),
      strings.collectionTracksCount(summary.trackCount),
      if (durationLabel != null) durationLabel,
      ...summary.formats,
    ];

    final captionStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Wrap(
      key: const ValueKey('collection-summary-chips'),
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 6,
      children: [
        for (var i = 0; i < facts.length; i++) ...[
          if (i != 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('·', style: captionStyle),
            ),
          Text(facts[i], style: captionStyle),
        ],
      ],
    );
  }
}
