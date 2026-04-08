import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_player/features/audio_player/handler/audio_handler.dart';
import 'app.dart';
import 'injection/injection_container.dart';

late AppAudioHandler audioHandler;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await initDependencies();

  runApp(const MediaPlayerApp());
}
