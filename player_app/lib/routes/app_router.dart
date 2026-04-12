import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/audio_player/presentation/pages/audio_player_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/playlist/domain/entities/media_item.dart';
import '../features/video_player/presentation/pages/video_player_page.dart';

abstract final class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: '/home',
      debugLogDiagnostics: false,
      routes: [
        GoRoute(
          path:    '/home',
          name:    'home',
          builder: (_, __) => const HomePage(),
        ),

        // FIX: audio-player now accepts a MediaItem via state.extra so the
        // page can display track info (title/artist/album art) immediately
        // while AudioBloc is still loading — no more blank/frozen screen.
        GoRoute(
          path: '/audio-player',
          name: 'audio-player',
          pageBuilder: (_, state) {
            final item = state.extra as MediaItem?;
            return CustomTransitionPage(
              key:   state.pageKey,
              child: AudioPlayerPage(initialItem: item),
              transitionsBuilder: (_, animation, __, child) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end:   Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve:  Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),

        GoRoute(
          path: '/video-player',
          name: 'video-player',
          pageBuilder: (_, state) {
            final item = state.extra as MediaItem;
            return CustomTransitionPage(
              key:   state.pageKey,
              child: VideoPlayerPage(item: item),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ],
    );
  }
}
