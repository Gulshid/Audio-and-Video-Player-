import 'package:get_it/get_it.dart';

import '../core/theme/theme_cubit.dart';
import '../features/audio_player/bloc/audio_bloc.dart';
import '../features/playlist/bloc/playlist_bloc.dart';
import '../features/video_player/bloc/video_bloc.dart';

/// Global service-locator instance.
final sl = GetIt.instance;

/// Call once in [main] before [runApp].
Future<void> initDependencies() async {
  // ── Cubits / BLoCs ───────────────────────────────────────
  // registerFactory → new instance every time it's requested.
  // registerLazySingleton → created once, reused everywhere.

  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit());

  // AudioBloc is a singleton so the mini-player and the full
  // player page share the same playback state.
  sl.registerLazySingleton<AudioBloc>(() => AudioBloc());

  // VideoBloc is also a singleton so navigation to the video
  // page doesn't lose state.
  sl.registerLazySingleton<VideoBloc>(() => VideoBloc());

  // PlaylistBloc is a singleton — one source of truth for the
  // media library throughout the app.
  sl.registerLazySingleton<PlaylistBloc>(() => PlaylistBloc());
}
