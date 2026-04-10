import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_player/features/audio_player/handler/audio_handler.dart';
import 'app.dart';
import 'injection/injection_container.dart';

// Assigned in main() before runApp — never a LateInitializationError.
late AppAudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive: init + open boxes BEFORE initDependencies ─────
  // Adapters must be registered before any box is opened.
  // initDependencies() triggers PlaylistBloc which calls
  // Hive.box(AppConstants.playlistBox) — so we open it here first.
  await Hive.initFlutter();
  // Register any custom TypeAdapters here before opening boxes, e.g.:
  // Hive.registerAdapter(MyAdapter());
  await Hive.openBox('playlist_box'); // matches AppConstants.playlistBox

  // ── Wire up GetIt singletons ─────────────────────────────
  await initDependencies();

  // ── Assign the global so AudioHandler is reachable ──────
  // sl<AppAudioHandler>() is registered inside initDependencies().
  audioHandler = sl<AppAudioHandler>();

  runApp(const MediaPlayerApp());
}