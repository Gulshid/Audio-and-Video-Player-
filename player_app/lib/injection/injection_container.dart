import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart'; // ← add this
import '../core/theme/theme_cubit.dart';
import '../features/audio_player/bloc/audio_bloc.dart';
import '../features/audio_player/handler/audio_handler.dart';
import '../features/playlist/bloc/playlist_bloc.dart';
import '../features/video_player/bloc/video_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── Audio handler ────────────────────────────────────────
  final audioHandler = await AudioService.init(
    builder: () => AppAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId:   'com.example.player_app',
      androidNotificationChannelName: 'Media Playback',
      androidNotificationOngoing:     true,
      androidStopForegroundOnPause:   true,
      notificationColor:              Color(0xFF7C6FF7), // MidnightViolet.primary
      androidNotificationIcon: 'drawable/audio',  // uses your existing audio.png
    ),
  );
  sl.registerSingleton<AppAudioHandler>(audioHandler);

  // ── Cubits / BLoCs ───────────────────────────────────────
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  sl.registerLazySingleton<PlaylistBloc>(() => PlaylistBloc());
  sl.registerLazySingleton<AudioBloc>(
    () => AudioBloc(
      handler:      sl<AppAudioHandler>(),
      playlistBloc: sl<PlaylistBloc>(),
    ),
  );
  sl.registerLazySingleton<VideoBloc>(
    () => VideoBloc(playlistBloc: sl<PlaylistBloc>()),
  );
}