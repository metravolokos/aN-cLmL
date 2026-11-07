import 'package:cloudmail_player/app/shell.dart';
import 'package:cloudmail_player/app/state.dart';
import 'package:cloudmail_player/data/library/cloud_music_service.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/l10n/app_localizations.dart';
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

class _CatalogFixture extends CloudCatalogController {
  @override
  List<RemoteTrack> build() => const [_track];
}

Future<void> openLibraryTab(WidgetTester tester, String tab) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [cloudCatalogProvider.overrideWith(_CatalogFixture.new)],
      child: const MaterialApp(
        locale: Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: AppShell(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('nav-$tab')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'album slides up below one immobile bottom bar and slides down on Back',
    (tester) async {
      await openLibraryTab(tester, 'albums');
      final bar = find.byKey(const ValueKey('navigation-bar'));
      final originalElement = tester.element(bar);
      final originalTop = tester.getTopLeft(bar);
      expect(find.byKey(const ValueKey('album-grid')), findsOneWidget);

      await tester.tap(find.byKey(ValueKey('album-open-${_track.albumKey}')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final risingTop = tester.getTopLeft(
        find.byKey(const ValueKey('library-detail-slide')),
      );
      await tester.pumpAndSettle();
      final settledTop = tester.getTopLeft(
        find.byKey(const ValueKey('library-detail-slide')),
      );

      expect(risingTop.dy, greaterThan(settledTop.dy + 10));
      expect(find.byKey(const ValueKey('album-detail-scroll')), findsOneWidget);
      expect(find.byKey(const ValueKey('album-detail-back')), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(bar, findsOneWidget);
      expect(identical(tester.element(bar), originalElement), isTrue);
      expect(tester.getTopLeft(bar), originalTop);

      await tester.tap(find.byKey(const ValueKey('album-detail-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('album-detail-scroll')), findsNothing);
      expect(find.byKey(const ValueKey('album-grid')), findsOneWidget);
      expect(identical(tester.element(bar), originalElement), isTrue);
      expect(tester.getTopLeft(bar), originalTop);

      // Selecting the already active tab also closes a detail page.
      await tester.tap(find.byKey(ValueKey('album-open-${_track.albumKey}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-albums')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('album-detail-scroll')), findsNothing);
      expect(bar, findsOneWidget);
    },
  );

  testWidgets('artist details and nested album keep the same shell bar', (
    tester,
  ) async {
    await openLibraryTab(tester, 'artists');
    final bar = find.byKey(const ValueKey('navigation-bar'));
    final originalElement = tester.element(bar);
    final originalTop = tester.getTopLeft(bar);

    await tester.tap(find.byKey(const ValueKey('artist-open-Artist')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('artist-detail-scroll')), findsOneWidget);
    expect(find.byKey(const ValueKey('artist-detail-back')), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(bar, findsOneWidget);
    expect(identical(tester.element(bar), originalElement), isTrue);

    final scrollable = find.byType(Scrollable);
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('artist-album-${_track.albumKey}')),
      140,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('artist-album-${_track.albumKey}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('album-detail-scroll')), findsOneWidget);
    expect(bar, findsOneWidget);
    expect(identical(tester.element(bar), originalElement), isTrue);
    expect(tester.getTopLeft(bar), originalTop);

    await tester.tap(find.byKey(const ValueKey('album-detail-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('artist-detail-scroll')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('artist-detail-scroll')), findsNothing);
    expect(find.byKey(const ValueKey('artist-list')), findsOneWidget);
    expect(bar, findsOneWidget);
    expect(identical(tester.element(bar), originalElement), isTrue);

    final container = ProviderScope.containerOf(tester.element(bar));
    expect(container.read(destinationProvider), AppDestination.artists);
    expect(tester.takeException(), isNull);
  });
}
