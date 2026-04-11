import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/audio_player/bloc/audio_bloc.dart';
import '../features/audio_player/bloc/audio_state.dart';
import '../features/audio_player/presentation/pages/audio_player_page.dart';
import '../features/audio_player/presentation/widgets/audio_mini_player.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/playlist/domain/entities/media_item.dart';
import '../features/video_player/presentation/pages/video_player_page.dart';

abstract final class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: '/home',
      debugLogDiagnostics: false,
      routes: [

        // ── Shell: wraps all main pages with mini player ──
        ShellRoute(
          builder: (context, state, child) => _AppShell(child: child),
          routes: [
            GoRoute(
              path:    '/home',
              name:    'home',
              builder: (_, __) => const HomePage(),
            ),
          ],
        ),

        // ── Full-screen players (outside shell, no mini player) ──
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

// ── Shell scaffold: hosts the mini player above every main page ──
class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 'child' is whichever ShellRoute page is active (HomePage, etc.)
      // HomePage already has its own Scaffold with bottom nav — so we
      // use a Stack + Positioned to float the mini player above it.
      body: Stack(
        children: [
          child,

          // Mini player floats above the bottom nav bar
          Positioned(
            left:   0,
            right:  0,
            // 56 = typical BottomNavigationBar height; adjust if yours differs
            bottom: 56,
            child: BlocBuilder<AudioBloc, AudioState>(
              builder: (context, state) {
                if (state is! AudioReady) return const SizedBox.shrink();
                return const AudioMiniPlayer();
              },
            ),
          ),
        ],
      ),
    );
  }
}