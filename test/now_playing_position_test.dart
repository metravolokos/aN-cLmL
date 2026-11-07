import 'package:cloudmail_player/data/audio/playback_controller.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/l10n/app_localizations.dart';
import 'package:cloudmail_player/presentation/now_playing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ProgressFixture extends PlaybackController {
  @override
  PlaybackView build() => const PlaybackView(
    track: RemoteTrack(
      path: 'track.mp3',
      sizeBytes: 10000,
      title: 'Song',
      artist: 'Artist',
      album: 'Album',
    ),
    playing: true,
    position: Duration(seconds: 20),
    duration: Duration(minutes: 3, seconds: 15),
    bufferedFraction: 0.6,
  );

  void advance() {
    state = state.withUpdates(position: const Duration(seconds: 43));
  }

  void clearDuration() {
    state = const PlaybackView(
      track: RemoteTrack(
        path: 'track.mp3',
        sizeBytes: 10000,
        title: 'Song',
        artist: 'Artist',
      ),
      playing: true,
      position: Duration(seconds: 43),
    );
  }
}

void main() {
  testWidgets('elapsed time and seek thumb follow playback position', (
    tester,
  ) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playbackControllerProvider.overrideWith(_ProgressFixture.new),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              locale: const Locale('ru'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const NowPlayingPage(),
            );
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.text('0:20'), findsOneWidget);
    expect(find.text('3:15'), findsOneWidget);
    expect(
      tester
          .widget<Slider>(find.byKey(const ValueKey('now-playing-seek')))
          .value,
      20000,
    );
    expect(
      tester
          .widget<Slider>(find.byKey(const ValueKey('now-playing-seek')))
          .secondaryTrackValue,
      117000,
    );

    (container.read(playbackControllerProvider.notifier) as _ProgressFixture)
        .advance();
    await tester.pump();
    expect(find.text('0:43'), findsOneWidget);
    expect(
      tester
          .widget<Slider>(find.byKey(const ValueKey('now-playing-seek')))
          .value,
      43000,
    );

    (container.read(playbackControllerProvider.notifier) as _ProgressFixture)
        .clearDuration();
    await tester.pump();
    expect(find.text('0:43'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('now-playing-seek')),
    );
    expect(slider.secondaryTrackValue, isNull);
    expect(slider.onChanged, isNull);
  });

  test('source duration is recovered before falling back to indexed tags', () {
    expect(
      resolvedPlaybackDuration(
        sourceDuration: const Duration(minutes: 2),
        taggedDuration: const Duration(minutes: 3),
      ),
      const Duration(minutes: 2),
    );
    expect(
      resolvedPlaybackDuration(
        sourceDuration: Duration.zero,
        taggedDuration: const Duration(minutes: 3),
      ),
      const Duration(minutes: 3),
    );
    expect(
      resolvedPlaybackDuration(
        playerDuration: const Duration(minutes: 4),
        taggedDuration: const Duration(minutes: 3),
      ),
      const Duration(minutes: 4),
    );
    expect(resolvedPlaybackDuration(), Duration.zero);
  });
}
