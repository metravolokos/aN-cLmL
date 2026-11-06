import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/audio/media_tag_factory.dart';
import 'platform/android/android_audio_session.dart';
import 'platform/android/android_background_audio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAndroidPlaybackControls();
  await configureAndroidMusicAudioSession();
  runApp(
    ProviderScope(
      overrides: [mediaTagFactoryProvider.overrideWithValue(androidMediaTag)],
      child: const AndroidMediaSessionBridge(child: CloudMailApp()),
    ),
  );
}
