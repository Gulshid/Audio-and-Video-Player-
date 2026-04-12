// ignore_for_file: unnecessary_cast

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

import '../../../../features/playlist/bloc/playlist_bloc.dart';
import '../../../../features/playlist/bloc/playlist_event.dart';
import '../../../../features/playlist/bloc/playlist_state.dart';
import '../../../../features/playlist/domain/entities/media_item.dart';
import '../../bloc/video_bloc.dart';
import '../../bloc/video_event.dart';
import '../../bloc/video_state.dart';
import '../widgets/video_controls.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Seek ripple model
// ─────────────────────────────────────────────────────────────────────────────

enum _SeekSide { left, right }

class _SeekRipple {
  _SeekRipple(this.side);
  final _SeekSide side;
}

// ─────────────────────────────────────────────────────────────────────────────
// VideoPlayerPage
// ─────────────────────────────────────────────────────────────────────────────

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({required this.item, super.key});
  final MediaItem item;

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  // ── Controls visibility ───────────────────────────────────────────────────
  bool _showControls = true;
  Timer? _hideTimer;

  // ── Lock screen ───────────────────────────────────────────────────────────
  bool _locked = false;

  // ── Seek ripple ───────────────────────────────────────────────────────────
  _SeekRipple? _seekRipple;
  Timer? _rippleTimer;

  // ── Horizontal drag seek ──────────────────────────────────────────────────
  bool _horizontalDragging = false;
  double _dragSeekMs = 0;
  double _dragStartMs = 0;

  late final VideoBloc _videoBloc;
  late final PlaylistBloc _playlistBloc;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _videoBloc = context.read<VideoBloc>();
    _playlistBloc = context.read<PlaylistBloc>();
    _videoBloc.add(VideoInitializeEvent(widget.item));
    _applyImmersiveMode();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _rippleTimer?.cancel();
    _videoBloc.add(const VideoDisposeEvent());
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

  void _onVideoTap() {
  if (!mounted) return;
  if (_showControls) {
    // Controls visible → hide immediately, cancel pending timer
    _hideTimer?.cancel();
    setState(() => _showControls = false);
  } else {
    // Controls hidden → show and schedule auto-hide
    setState(() => _showControls = true);
    _scheduleHide();
  }
}

 void _onControlInteraction() {
  if (!mounted) return;
  if (!_showControls) setState(() => _showControls = true);
  _scheduleHide(); // always reset the 2s countdown
}

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  

  // ── Lock ──────────────────────────────────────────────────────────────────

  void _toggleLock() {
    setState(() {
      _locked = !_locked;
      _showControls = true;
    });
    _scheduleHide();
  }

  // ── Double-tap seek ───────────────────────────────────────────────────────

  void _doubleTapSeek(_SeekSide side) {
    _videoBloc.add(
      side == _SeekSide.left
          ? const VideoSkipBackwardEvent()
          : const VideoSkipForwardEvent(),
    );
    _showRipple(side);
    _onControlInteraction();
  }

  void _showRipple(_SeekSide side) {
    _rippleTimer?.cancel();
    setState(() => _seekRipple = _SeekRipple(side));
    _rippleTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _seekRipple = null);
    });
  }

  // ── Horizontal drag seek ──────────────────────────────────────────────────

  void _onHorizontalDragStart(DragStartDetails d) {
    final state = _videoBloc.state;
    if (state is! VideoReady) return;
    _horizontalDragging = true;
    _dragStartMs = state.position.inMilliseconds.toDouble();
    _dragSeekMs = _dragStartMs;
    _onControlInteraction();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    if (!_horizontalDragging) return;
    final state = _videoBloc.state;
    if (state is! VideoReady) return;
    final delta = d.primaryDelta ?? 0;
    final maxMs = state.duration.inMilliseconds.toDouble();
    _dragSeekMs = (_dragSeekMs + delta * 500).clamp(0.0, maxMs);
    setState(() {});
  }

  void _onHorizontalDragEnd(DragEndDetails _) {
    if (!_horizontalDragging) return;
    _horizontalDragging = false;
    _videoBloc.add(VideoSeekEvent(Duration(milliseconds: _dragSeekMs.toInt())));
    setState(() {});
  }

  // ── Build ─────────────────────────────────────────────────────────────────

 @override
Widget build(BuildContext context) {
  return PopScope(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) _restoreSystemUI();
    },
    child: BlocListener<VideoBloc, VideoState>(
      listenWhen: (prev, curr) =>
          prev is VideoReady &&
          curr is VideoReady &&
          (prev as VideoReady).isFullscreen !=
              (curr as VideoReady).isFullscreen,
      listener: (context, state) {
        if (state is! VideoReady) return;
        if (state.isFullscreen) {
          // Lock to landscape
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        } else {
          // Restore portrait + landscape allowed
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
            DeviceOrientation.portraitUp,
          ]);
        }
      },
      child: BlocListener<PlaylistBloc, PlaylistState>(
        listenWhen: (prev, next) {
          if (next is! PlaylistLoaded) return false;
          if (prev is! PlaylistLoaded) return next.nowPlaying != null;
          return prev.nowPlaying != next.nowPlaying &&
              next.nowPlaying != null;
        },
        listener: (context, state) {
          if (state is! PlaylistLoaded) return;
          final item = state.nowPlaying;
          if (item == null) return;
          _playlistBloc.add(const PlaylistConsumeNowPlayingEvent());
          _videoBloc.add(VideoInitializeEvent(item));
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: BlocBuilder<VideoBloc, VideoState>(
            builder: (context, state) {
              if (state is VideoInitial) return const SizedBox.expand();
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
                  state: state,
                  showControls: _showControls,
                  locked: _locked,
                  seekRipple: _seekRipple,
                  horizontalDragging: _horizontalDragging,
                  dragSeekMs: _dragSeekMs,
                  onVideoTap: _onVideoTap,
                  onControlInteraction: _onControlInteraction,
                  onToggleLock: _toggleLock,
                  onDoubleTapLeft: () => _doubleTapSeek(_SeekSide.left),
                  onDoubleTapRight: () => _doubleTapSeek(_SeekSide.right),
                  onHDragStart: _onHorizontalDragStart,
                  onHDragUpdate: _onHorizontalDragUpdate,
                  onHDragEnd: _onHorizontalDragEnd,
                );
              }
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    ),
  );
}
}

// ─────────────────────────────────────────────────────────────────────────────
// _VideoSurface
// ─────────────────────────────────────────────────────────────────────────────

class _VideoSurface extends StatelessWidget {
  const _VideoSurface({
    required this.state,
    required this.showControls,
    required this.locked,
    required this.seekRipple,
    required this.horizontalDragging,
    required this.dragSeekMs,
    required this.onVideoTap,
    required this.onControlInteraction,
    required this.onToggleLock,
    required this.onDoubleTapLeft,
    required this.onDoubleTapRight,
    required this.onHDragStart,
    required this.onHDragUpdate,
    required this.onHDragEnd,
  });

  final VideoReady state;
  final bool showControls;
  final bool locked;
  final _SeekRipple? seekRipple;
  final bool horizontalDragging;
  final double dragSeekMs;
  final VoidCallback onVideoTap;
  final VoidCallback onControlInteraction;
  final VoidCallback onToggleLock;
  final VoidCallback onDoubleTapLeft;
  final VoidCallback onDoubleTapRight;
  final GestureDragStartCallback onHDragStart;
  final GestureDragUpdateCallback onHDragUpdate;
  final GestureDragEndCallback onHDragEnd;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Video surface ────────────────────────────────────────────────
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onVideoTap,
          onHorizontalDragStart: onHDragStart,
          onHorizontalDragUpdate: onHDragUpdate,
          onHorizontalDragEnd: onHDragEnd,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ratio = state.controller.value.aspectRatio;
              final maxW = constraints.maxWidth;
              final maxH = constraints.maxHeight;
              final fitW = maxH * ratio;
              final w = fitW > maxW ? maxW : fitW;
              final h = fitW > maxW ? maxW / ratio : maxH;
              return Center(
                child: SizedBox(
                  width: w,
                  height: h,
                  child: VideoPlayer(state.controller),
                ),
              );
            },
          ),
        ),

        // ── Double-tap seek zones ────────────────────────────────────────
        if (!locked) ...[
          _DoubleTapZone(
            alignment: Alignment.centerLeft,
            onDoubleTap: onDoubleTapLeft,
          ),
          _DoubleTapZone(
            alignment: Alignment.centerRight,
            onDoubleTap: onDoubleTapRight,
          ),
        ],

        // ── Seek ripple ──────────────────────────────────────────────────
        if (seekRipple != null) _SeekRippleOverlay(side: seekRipple!.side),

        // ── Drag seek overlay ────────────────────────────────────────────
        if (horizontalDragging)
          _DragSeekOverlay(
            positionMs: dragSeekMs,
            durationMs: state.duration.inMilliseconds.toDouble(),
          ),

        // ── Controls overlay ─────────────────────────────────────────────
        Positioned.fill(
          child: SafeArea(
            child: AnimatedOpacity(
              opacity: showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !showControls,
                child: GestureDetector(
                  onTap: onControlInteraction,
                  behavior: HitTestBehavior.translucent,
                  child: VideoControls(
                    locked: locked,
                    onToggleLock: onToggleLock,
                  ),
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
// Double-tap zone
// ─────────────────────────────────────────────────────────────────────────────

class _DoubleTapZone extends StatelessWidget {
  const _DoubleTapZone({required this.alignment, required this.onDoubleTap});
  final Alignment alignment;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.33,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: onDoubleTap,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seek ripple overlay
// ─────────────────────────────────────────────────────────────────────────────

class _SeekRippleOverlay extends StatelessWidget {
  const _SeekRippleOverlay({required this.side});
  final _SeekSide side;

  @override
  Widget build(BuildContext context) {
    final isLeft = side == _SeekSide.left;
    return Positioned.fill(
      child: Align(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.33,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLeft ? Icons.replay_10_rounded : Icons.forward_10_rounded,
                color: Colors.white,
                size: 40.r,
              ),
              SizedBox(height: 6.h),
              Text(
                isLeft ? '−10 sec' : '+10 sec',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drag seek overlay
// ─────────────────────────────────────────────────────────────────────────────

class _DragSeekOverlay extends StatelessWidget {
  const _DragSeekOverlay({required this.positionMs, required this.durationMs});
  final double positionMs;
  final double durationMs;

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final pos = Duration(milliseconds: positionMs.toInt());
    final dur = Duration(milliseconds: durationMs.toInt());

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.72),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _fmt(pos),
              style: TextStyle(
                color: Colors.white,
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(2.r),
              child: LinearProgressIndicator(
                value: durationMs > 0 ? positionMs / durationMs : 0,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                minHeight: 3,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              _fmt(dur),
              style: TextStyle(color: Colors.white54, fontSize: 11.sp),
            ),
          ],
        ),
      ),
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
            Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 64.r,
            ),
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
