import 'package:cloudmail_player/data/audio/playback_controller.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/l10n/app_localizations.dart';
import 'package:cloudmail_player/presentation/now_playing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePlaybackController extends PlaybackController {
  @override
  PlaybackView build() => const PlaybackView(
    track: RemoteTrack(
      path: 'Тестовый трек.flac',
      sizeBytes: 200000,
      title: 'Моя песня',
      artist: 'Исполнитель',
      album: 'Альбом',
    ),
    position: Duration(seconds: 12),
    duration: Duration(seconds: 45),
    bufferedFraction: 0.75,
    loading: true,
    playing: false,
  );
}

void main() {
  testWidgets('full Now Playing displays Russian title and position', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playbackControllerProvider.overrideWith(FakePlaybackController.new),
        ],
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NowPlayingPage(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Сейчас играет'), findsOneWidget);
    expect(find.text('Моя песня'), findsOneWidget);
    expect(find.text('Исполнитель'), findsOneWidget);
    expect(find.text('Альбом'), findsOneWidget);
    expect(find.text('0:12'), findsOneWidget);
    expect(find.text('0:45'), findsOneWidget);
    expect(find.byKey(const ValueKey('buffered-seek-track')), findsOneWidget);
    expect(find.byKey(const ValueKey('buffered-waveform')), findsNothing);
    expect(
      tester
          .widget<FractionallySizedBox>(
            find.byKey(const ValueKey('seek-buffered-fill')),
          )
          .widthFactor,
      0.75,
    );
    expect(
      tester
          .widget<FractionallySizedBox>(
            find.byKey(const ValueKey('seek-played-fill')),
          )
          .widthFactor,
      closeTo(12 / 45, 0.001),
    );
    expect(find.byKey(const ValueKey('now-playing-seek')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
