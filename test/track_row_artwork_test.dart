import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudmail_player/data/library/cloud_music_service.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/l10n/app_localizations.dart';
import 'package:cloudmail_player/presentation/library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _track = RemoteTrack(
  path: '/AllMusic/track.flac',
  sizeBytes: 1234,
  title: 'Название песни',
  artist: 'Имя исполнителя',
  album: 'Альбом',
);

class _Thumbnails extends CloudMusicService {
  _Thumbnails({required this.artworkAvailable});
  final bool artworkAvailable;
  final requests = <String>[];

  @override
  Future<Uint8List?> readThumbnail(RemoteTrack track) async {
    requests.add(track.path);
    if (!artworkAvailable) return null;
    return Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/lX8AAAAASUVORK5CYII=',
      ),
    );
  }
}

Future<void> _pumpRow(WidgetTester tester, _Thumbnails service) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [cloudMusicServiceProvider.overrideWithValue(service)],
      child: const MaterialApp(
        locale: Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: TrackListRow(track: _track, queue: [_track]),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('track row shows artwork, title and artist instead of filename', (
    tester,
  ) async {
    final service = _Thumbnails(artworkAvailable: true);
    await _pumpRow(tester, service);
    expect(service.requests, ['/AllMusic/track.flac']);
    expect(find.text('Название песни'), findsOneWidget);
    expect(find.text('Имя исполнителя'), findsOneWidget);
    expect(find.text('track.flac'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(
      find.byKey(const ValueKey('track-more-/AllMusic/track.flac')),
      findsOneWidget,
    );
  });

  testWidgets('missing embedded artwork shows a safe placeholder', (
    tester,
  ) async {
    final service = _Thumbnails(artworkAvailable: false);
    await _pumpRow(tester, service);
    expect(service.requests, ['/AllMusic/track.flac']);
    expect(find.byIcon(Icons.album_outlined), findsOneWidget);
    expect(find.text('Название песни'), findsOneWidget);
    expect(find.text('Имя исполнителя'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
