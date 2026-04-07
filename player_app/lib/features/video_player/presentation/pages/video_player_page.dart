import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

import '../../../../features/playlist/domain/entities/media_item.dart';
import '../../bloc/video_bloc.dart';
import '../../bloc/video_event.dart';
import '../../bloc/video_state.dart';
import '../widgets/video_controls.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({required this.item, super.key});
  final MediaItem item;

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  // ── Controls visibility — single source of truth ─────────────────────────
  // VideoControls has NO internal timer or visibility state.
  // This page is the only place that owns show/hide logic.
  bool   _showControls = true;
  Timer? _hideTimer;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
late final VideoBloc _videoBloc;

@override
void initState() {
  super.initState();
  _videoBloc = context.read<VideoBloc>(); // cache it here — tree is alive
  _videoBloc.add(VideoInitializeEvent(widget.item));
  _applyImmersiveMode();
  _scheduleHide();
}

@override
void dispose() {
  _hideTimer?.cancel();
  _videoBloc.add(const VideoDisposeEvent()); // no context needed
  _restoreSystemUI();
  super.dispose();
}

  // ── System UI ─────────────────────────────────────────────────────────────

  void _applyImmersiveMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _restoreSystemUI() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // ── Controls visibility ───────────────────────────────────────────────────

  /// Tap anywhere on the video surface → toggle controls.
  void _onVideoTap() {
    if (!mounted) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _scheduleHide();
    } else {
      _hideTimer?.cancel();
    }
  }

  /// After any control interaction, reset the 3-second hide countdown.
  void _onControlInteraction() {
    if (!mounted) return;
    setState(() => _showControls = true);
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _restoreSystemUI();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocBuilder<VideoBloc, VideoState>(
          builder: (context, state) {
            if (state is VideoInitial) {
              // Pure black — no spinner flash before loading begins
              return const SizedBox.expand();
            }

            if (state is VideoLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (state is VideoError) {
              return _ErrorView(message: state.message);
            }

            if (state is VideoReady) {
              return _VideoSurface(
                state:                state,
                showControls:         _showControls,
                onVideoTap:           _onVideoTap,
                onControlInteraction: _onControlInteraction,
              );
            }

            return const SizedBox.expand();
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Video surface + controls overlay — extracted so BlocBuilder only rebuilds
// this subtree on state changes, not the whole page.
// ─────────────────────────────────────────────────────────────────────────────

class _VideoSurface extends StatelessWidget {
  const _VideoSurface({
    required this.state,
    required this.showControls,
    required this.onVideoTap,
    required this.onControlInteraction,
  });

  final VideoReady state;
  final bool       showControls;
  final VoidCallback onVideoTap;
  final VoidCallback onControlInteraction;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Video surface — tap to toggle controls ───────────────────────
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap:    onVideoTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ratio = state.controller.value.aspectRatio;
              final maxW  = constraints.maxWidth;
              final maxH  = constraints.maxHeight;
              final fitW  = maxH * ratio;
              final w     = fitW > maxW ? maxW : fitW;
              final h     = fitW > maxW ? maxW / ratio : maxH;

              return Center(
                child: SizedBox(
                  width:  w,
                  height: h,
                  child:  VideoPlayer(state.controller),
                ),
              );
            },
          ),
        ),

        // ── Controls overlay — SafeArea clears notch & nav bar ───────────
        // Wrapped in IgnorePointer when hidden so taps fall through to the
        // GestureDetector above and bring the controls back.
        Positioned.fill(
          child: SafeArea(
            child: AnimatedOpacity(
              opacity:  showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                // When controls are invisible, ignore taps on the overlay
                // so the GestureDetector on the video surface can catch them.
                ignoring: !showControls,
                child: GestureDetector(
                  // Any tap on the controls resets the auto-hide timer
                  onTap: onControlInteraction,
                  // absorb: false so the child buttons still receive their taps
                  behavior: HitTestBehavior.translucent,
                  child: const VideoControls(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 64.r),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}