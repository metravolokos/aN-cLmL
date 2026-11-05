import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'app/app.dart';
import 'platform/android/android_background_audio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAndroidPlaybackControls();
  // Registers the native libmpv backend for Windows and Linux. Android keeps
  // just_audio's standard Media3 ExoPlayer implementation.
  JustAudioMediaKit.ensureInitialized();
  runApp(const ProviderScope(child: CloudMailApp()));
}
