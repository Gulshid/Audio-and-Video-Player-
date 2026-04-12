import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/audio_player/presentation/pages/audio_player_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/playlist/domain/entities/media_item.dart';
import '../features/video_player/presentation/pages/video_player_page.dart';

// FIX #1 & #2: The _AppShell that previously rendered AudioMiniPlayer here
// has been removed. The mini player is now rendered exclusively inside
// HomePage's _PhoneShell and _TabletShell, which already have access to the
// correct bottom offset (respecting the nav bar height and SafeArea insets).
// This eliminates the double-render and the hardcoded `bottom: 56` bug.

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

        // ── Full-screen players (no mini player) ──────────
        GoRoute(
          path: '/audio-player',
          name: 'audio-player',
          pageBuilder: (_, state) => CustomTransitionPage(
            key:   state.pageKey,
            child: const AudioPlayerPage(),
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
          ),
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
