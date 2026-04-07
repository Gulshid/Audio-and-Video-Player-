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
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit());

  // PlaylistBloc must be registered first — AudioBloc depends on it
  // so it can persist playback positions back into Hive.
  sl.registerLazySingleton<PlaylistBloc>(() => PlaylistBloc());

  // AudioBloc receives a reference to PlaylistBloc so it can call
  // PlaylistUpdatePositionEvent when a track changes or stops.
  sl.registerLazySingleton<AudioBloc>(
    () => AudioBloc(playlistBloc: sl<PlaylistBloc>()),
  );

  // VideoBloc receives a reference to PlaylistBloc for the same reason.
  sl.registerLazySingleton<VideoBloc>(
    () => VideoBloc(playlistBloc: sl<PlaylistBloc>()),
  );
}
