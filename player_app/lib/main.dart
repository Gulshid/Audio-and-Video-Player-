import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'injection/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive local storage ───────────────────────────────────
  await Hive.initFlutter();

  // ── Service locator ──────────────────────────────────────
  await initDependencies();

  runApp(const MediaPlayerApp());
}
