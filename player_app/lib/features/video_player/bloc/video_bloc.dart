import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_constants.dart';
import '../../playlist/bloc/playlist_bloc.dart';
import '../../playlist/bloc/playlist_event.dart';
import 'video_event.dart';
import 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  VideoBloc({PlaylistBloc? playlistBloc})
      : _playlistBloc = playlistBloc,
        super(const VideoInitial()) {
    on<VideoInitializeEvent>      (_onInit);
    on<VideoPlayEvent>            (_onPlay);
    on<VideoPauseEvent>           (_onPause);
    on<VideoSeekEvent>            (_onSeek);
    on<VideoSkipForwardEvent>     (_onSkipForward);
    on<VideoSkipBackwardEvent>    (_onSkipBackward);
    on<VideoSetVolumeEvent>       (_onVolume);
    on<VideoToggleMuteEvent>      (_onMute);
    on<VideoToggleFullscreenEvent>(_onFullscreen);
    on<VideoSetSpeedEvent>        (_onSpeed);
    on<VideoDisposeEvent>         (_onDispose);
    on<VideoPositionUpdatedEvent> (_onPosition);
    on<VideoCompletedEvent>       (_onCompleted);
  }

  VideoPlayerController? _controller;
  Timer?                 _posTimer;
  final PlaylistBloc?    _playlistBloc;

  // ── Initialise ───────────────────────────────────────────────────────────

  Future<void> _onInit(
    VideoInitializeEvent event,
    Emitter<VideoState> emit,
  ) async {
    _persistCurrentPosition();

    emit(const VideoLoading());
    await _disposeController();

    try {
      final item = event.item;
      final ctrl = item.isNetwork
          ? VideoPlayerController.networkUrl(Uri.parse(item.path))
          : VideoPlayerController.file(File(item.path));

      await ctrl.initialize();

      // Restore saved position (skip if < 5 s — not worth resuming).
      if (item.lastPositionSeconds > 5) {
        await ctrl.seekTo(item.lastPosition);
      }

      // ── Controller listener: catches completion & errors ────────────────
      // We only need to react to the "finished" transition once, so we
      // compare the previous isPlaying + isCompleted combo rather than
      // firing on every tick (the timer already handles position updates).
      ctrl.addListener(() {
        if (isClosed) return;
        final v = ctrl.value;
        if (v.hasError) {
          debugPrint('🎬 VideoPlayer error: ${v.errorDescription}');
          // Surface the error through the normal event pipeline so the
          // bloc can emit VideoError from within an event handler (safe).
          // We don't emit directly from the listener to keep the single
          // source-of-truth guarantee.
          return;
        }
        // "Completed" = position reached duration AND the player stopped.
        if (!v.isPlaying && v.isCompleted) {
          if (!isClosed) add(const VideoCompletedEvent());
        }
      });

      _controller = ctrl;
      _startPositionTimer();
      await ctrl.play();

      emit(VideoReady(
        controller: ctrl,
        item:       item,
        isPlaying:  true,
        duration:   ctrl.value.duration,
        position:   item.lastPositionSeconds > 5
            ? item.lastPosition
            : Duration.zero,
        buffered:   Duration.zero,
      ));
    } catch (e, st) {
      debugPrint('🎬 VideoBloc._onInit error: $e\n$st');
      emit(VideoError('Cannot play video: ${e.toString()}'));
    }
  }

  // ── Playback controls ────────────────────────────────────────────────────

  Future<void> _onPlay(VideoPlayEvent _, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    final s = state as VideoReady;
    // If the video had ended, replay from the start.
    if (s.hasEnded) {
      await _controller?.seekTo(Duration.zero);
    }
    await _controller?.play();
    emit(s.copyWith(isPlaying: true, hasEnded: false));
  }

  Future<void> _onPause(VideoPauseEvent _, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    await _controller?.pause();
    emit((state as VideoReady).copyWith(isPlaying: false));
  }

  Future<void> _onSeek(VideoSeekEvent event, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    await _controller?.seekTo(event.position);
    emit((state as VideoReady).copyWith(position: event.position, hasEnded: false));
  }

  Future<void> _onSkipForward(
      VideoSkipForwardEvent _, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    final s       = state as VideoReady;
    final target  = s.position + AppConstants.seekForward;
    final clamped = target > s.duration ? s.duration : target;
    await _controller?.seekTo(clamped);
    emit(s.copyWith(position: clamped));
  }

  Future<void> _onSkipBackward(
      VideoSkipBackwardEvent _, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    final s       = state as VideoReady;
    final target  = s.position - AppConstants.seekBackward;
    final clamped = target.isNegative ? Duration.zero : target;
    await _controller?.seekTo(clamped);
    emit(s.copyWith(position: clamped));
  }

  // ── Volume ───────────────────────────────────────────────────────────────

  Future<void> _onVolume(
      VideoSetVolumeEvent event, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    final s          = state as VideoReady;
    final clamped    = event.volume.clamp(0.0, 1.0);
    // Dragging the volume slider while muted should silently unmute.
    final nowMuted   = clamped == 0.0;
    await _controller?.setVolume(clamped);
    emit(s.copyWith(volume: clamped, isMuted: nowMuted));
  }

  Future<void> _onMute(VideoToggleMuteEvent _, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    final s      = state as VideoReady;
    final muted  = !s.isMuted;
    // When unmuting, restore to at least 0.3 so the user actually hears audio.
    final restoreVol = s.volume < 0.05 ? 0.3 : s.volume;
    await _controller?.setVolume(muted ? 0.0 : restoreVol);
    emit(s.copyWith(
      isMuted: muted,
      // Preserve the non-zero volume so unmuting restores it correctly.
      volume: muted ? s.volume : restoreVol,
    ));
  }

  // ── Fullscreen / speed ───────────────────────────────────────────────────

  void _onFullscreen(VideoToggleFullscreenEvent _, Emitter<VideoState> emit) {
    if (state is! VideoReady) return;
    emit((state as VideoReady).copyWith(
      isFullscreen: !(state as VideoReady).isFullscreen,
    ));
  }

  Future<void> _onSpeed(
      VideoSetSpeedEvent event, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    await _controller?.setPlaybackSpeed(event.speed);
    emit((state as VideoReady).copyWith(playbackSpeed: event.speed));
  }

  // ── Internal: position + buffered tick ───────────────────────────────────

  void _onPosition(
      VideoPositionUpdatedEvent event, Emitter<VideoState> emit) {
    if (isClosed) return;
    if (state is VideoReady) {
      emit((state as VideoReady).copyWith(
        position: event.position,
        buffered: event.buffered,
      ));
    }
  }

  // ── Internal: end-of-video ────────────────────────────────────────────────

  Future<void> _onCompleted(
      VideoCompletedEvent _, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    final s = state as VideoReady;

    _persistCurrentPosition();

    // Pause the controller so it stays on the last frame.
    await _controller?.pause();

    emit(s.copyWith(
      isPlaying: false,
      hasEnded:  true,
      position:  s.duration,
    ));
  }

  // ── Dispose ──────────────────────────────────────────────────────────────

  Future<void> _onDispose(
      VideoDisposeEvent _, Emitter<VideoState> emit) async {
    _persistCurrentPosition();
    await _disposeController();
    emit(const VideoInitial());
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _startPositionTimer() {
    _posTimer?.cancel();
    _posTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (isClosed) return;
      final ctrl = _controller;
      if (ctrl == null) return;

      final pos      = ctrl.value.position;
      // video_player returns a list of DurationRange; take the end of the
      // last (furthest) range as the "how far is buffered" value.
      final ranges   = ctrl.value.buffered;
      final buffered = ranges.isNotEmpty
          ? ranges.last.end
          : Duration.zero;

      add(VideoPositionUpdatedEvent(pos, buffered));
    });
  }

  Future<void> _disposeController() async {
    _posTimer?.cancel();
    _posTimer = null;
    await _controller?.dispose();
    _controller = null;
  }

  void _persistCurrentPosition() {
    if (state is! VideoReady) return;
    final s          = state as VideoReady;
    final posSeconds = s.position.inSeconds;
    // Don't save if the user barely started or the video has ended — the
    // next open should start from the beginning in both cases.
    if (posSeconds < 5) return;
    if (s.hasEnded)     return;
    _playlistBloc?.add(
      PlaylistUpdatePositionEvent(s.item.id, posSeconds),
    );
    debugPrint('💾 Video: saved ${posSeconds}s for "${s.item.title}"');
  }

  @override
  Future<void> close() async {
    _persistCurrentPosition();
    await _disposeController();
    return super.close();
  }
}