import 'package:cloudmail_player/app/state.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/l10n/app_localizations.dart';
import 'package:cloudmail_player/presentation/album_detail_page.dart';
import 'package:cloudmail_player/presentation/library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _track = RemoteTrack(
  path: 'Example.mp3',
  sizeBytes: 1024,
  title: 'Example',
  artist: 'Artist',
  album: 'Album',
);

Future<void> openDetail(WidgetTester tester, Widget detail) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const ValueKey('open-detail'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => detail),
                ),
                child: const Text('Open detail'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('open-detail')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('album keeps all four tabs and returns to selected destination', (
    tester,
  ) async {
    await openDetail(tester, const AlbumDetailPage(tracks: [_track]));
    expect(find.byKey(const ValueKey('album-detail-scroll')), findsOneWidget);
    final bar = tester.widget<NavigationBar>(
      find.byKey(const ValueKey('navigation-bar')),
    );
    expect(bar.destinations, hasLength(4));
    expect(bar.labelBehavior, NavigationDestinationLabelBehavior.alwaysHide);
    await tester.tap(find.byKey(const ValueKey('nav-tracks')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-detail')), findsOneWidget);
    expect(find.byKey(const ValueKey('album-detail-scroll')), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('open-detail'))),
    );
    expect(container.read(destinationProvider), AppDestination.tracks);
  });

  testWidgets('artist keeps tab navigation with the mini-player slot', (
    tester,
  ) async {
    await openDetail(
      tester,
      const ArtistDetailPage(artist: 'Artist', tracks: [_track]),
    );
    expect(find.byKey(const ValueKey('artist-detail-scroll')), findsOneWidget);
    expect(find.byKey(const ValueKey('navigation-bar')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-albums')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-detail')), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('open-detail'))),
    );
    expect(container.read(destinationProvider), AppDestination.albums);
    expect(tester.takeException(), isNull);
  });
}
