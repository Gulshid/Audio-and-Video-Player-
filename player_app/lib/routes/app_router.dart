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
        // ── Shell (bottom nav / rail) ───────────────────
        GoRoute(
          path:    '/home',
          name:    'home',
          builder: (_, __) => const HomePage(),
        ),

        // ── Full-screen audio player ────────────────────
        GoRoute(
          path:    '/audio-player',
          name:    'audio-player',
          pageBuilder: (_, state) => CustomTransitionPage(
            key:   state.pageKey,
            child: const AudioPlayerPage(),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end:   Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve:  Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          ),
        ),

        // ── Full-screen video player ────────────────────
        GoRoute(
          path:    '/video-player',
          name:    'video-player',
          pageBuilder: (_, state) {
            final item = state.extra as MediaItem;
            return CustomTransitionPage(
              key:   state.pageKey,
              child: VideoPlayerPage(item: item),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          },
        ),
      ],
    );
  }
}
