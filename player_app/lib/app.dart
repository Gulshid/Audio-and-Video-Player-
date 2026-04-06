// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/audio_player/bloc/audio_bloc.dart';
import 'features/playlist/bloc/playlist_bloc.dart';
import 'features/playlist/bloc/playlist_event.dart';
import 'features/video_player/bloc/video_bloc.dart';
import 'injection/injection_container.dart';
import 'routes/app_router.dart';

class MediaPlayerApp extends StatefulWidget {
  const MediaPlayerApp({super.key});

  @override
  State<MediaPlayerApp> createState() => _MediaPlayerAppState();
}

class _MediaPlayerAppState extends State<MediaPlayerApp>
    with WidgetsBindingObserver {
  late final _router = AppRouter.create();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Audio bloc handles pause-on-background internally via audio_service.
    // Nothing extra needed here unless you add analytics / logging.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ThemeCubit>()),
        BlocProvider(create: (_) => sl<AudioBloc>()),
        BlocProvider(create: (_) => sl<VideoBloc>()),
        BlocProvider(
          create: (_) => sl<PlaylistBloc>()..add(const PlaylistLoadEvent()),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ScreenUtilInit(
            designSize: _designSize(constraints.maxWidth),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (_, __) {
              return BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  return MaterialApp.router(
                    title: 'Media Player',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.light,
                    darkTheme: AppTheme.dark,
                    themeMode: themeMode,
                    routerConfig: _router,
                    builder: (ctx, child) {
                      // Sync status bar style with theme
                      SystemChrome.setSystemUIOverlayStyle(
                        SystemUiOverlayStyle(
                          statusBarColor: Colors.transparent,
                          systemNavigationBarColor: Colors.transparent,
                          systemNavigationBarContrastEnforced: false,
                          statusBarIconBrightness:
                              themeMode == ThemeMode.dark
                                  ? Brightness.light
                                  : Brightness.dark,
                          systemNavigationBarIconBrightness:
                              themeMode == ThemeMode.dark
                                  ? Brightness.light
                                  : Brightness.dark,
                        ),
                      );
                      return child!;
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Returns a design size that matches the device class.
/// Mirrors the same helper used in SwiftChat.
Size _designSize(double width) {
  if (width < 600) return const Size(360, 800);     // phone
  if (width < 1200) return const Size(834, 1194);   // tablet
  return const Size(1440, 1024);                     // desktop / large tablet
}
