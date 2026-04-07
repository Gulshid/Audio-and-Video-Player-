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
  }

  VideoPlayerController? _controller;
  Timer?                 _posTimer;
  final PlaylistBloc?    _playlistBloc;

  // ── Event handlers ───────────────────────────────────────

  Future<void> _onInit(
    VideoInitializeEvent event,
    Emitter<VideoState> emit,
  ) async {
    // Persist position of the previous video before replacing the controller
    _persistCurrentPosition();

    emit(const VideoLoading());
    await _disposeController();

    try {
      final item = event.item;
      final ctrl = item.isNetwork
          ? VideoPlayerController.networkUrl(Uri.parse(item.path))
          : VideoPlayerController.file(File(item.path));

      await ctrl.initialize();

      if (item.lastPositionSeconds > 0) {
        await ctrl.seekTo(item.lastPosition);
      }

      _controller = ctrl;
      _startPositionTimer();
      await ctrl.play();

      emit(VideoReady(
        controller: ctrl,
        item:       item,
        isPlaying:  true,
        duration:   ctrl.value.duration,
        position:   item.lastPosition,
      ));
    } catch (e) {
      emit(VideoError('Cannot play video: ${e.toString()}'));
    }
  }

  Future<void> _onPlay(VideoPlayEvent _, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    await _controller?.play();
    emit((state as VideoReady).copyWith(isPlaying: true));
  }

  Future<void> _onPause(VideoPauseEvent _, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    await _controller?.pause();
    emit((state as VideoReady).copyWith(isPlaying: false));
  }

  Future<void> _onSeek(VideoSeekEvent event, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    await _controller?.seekTo(event.position);
    emit((state as VideoReady).copyWith(position: event.position));
  }

  Future<void> _onSkipForward(VideoSkipForwardEvent _, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    final s       = state as VideoReady;
    final pos     = s.position + AppConstants.seekForward;
    final clamped = pos > s.duration ? s.duration : pos;
    await _controller?.seekTo(clamped);
    emit(s.copyWith(position: clamped));
  }

  Future<void> _onSkipBackward(VideoSkipBackwardEvent _, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    final s       = state as VideoReady;
    final pos     = s.position - AppConstants.seekBackward;
    final clamped = pos.isNegative ? Duration.zero : pos;
    await _controller?.seekTo(clamped);
    emit(s.copyWith(position: clamped));
  }

  Future<void> _onVolume(VideoSetVolumeEvent event, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    await _controller?.setVolume(event.volume.clamp(0.0, 1.0));
    emit((state as VideoReady).copyWith(volume: event.volume));
  }

  Future<void> _onMute(VideoToggleMuteEvent _, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    final s     = state as VideoReady;
    final muted = !s.isMuted;
    await _controller?.setVolume(muted ? 0 : s.volume);
    emit(s.copyWith(isMuted: muted));
  }

  void _onFullscreen(VideoToggleFullscreenEvent _, Emitter<VideoState> emit) {
    if (state is! VideoReady) return;
    emit((state as VideoReady).copyWith(
      isFullscreen: !(state as VideoReady).isFullscreen,
    ));
  }

  Future<void> _onSpeed(VideoSetSpeedEvent event, Emitter<VideoState> emit) async {
    if (state is! VideoReady) return;
    await _controller?.setPlaybackSpeed(event.speed);
    emit((state as VideoReady).copyWith(playbackSpeed: event.speed));
  }

  Future<void> _onDispose(VideoDisposeEvent _, Emitter<VideoState> emit) async {
    _persistCurrentPosition();
    await _disposeController();
    emit(const VideoInitial());
  }

  void _onPosition(VideoPositionUpdatedEvent event, Emitter<VideoState> emit) {
    if (state is VideoReady) {
      emit((state as VideoReady).copyWith(position: event.position));
    }
  }

  // ── Helpers ──────────────────────────────────────────────

  void _startPositionTimer() {
    _posTimer?.cancel();
    _posTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final pos = _controller?.value.position;
      if (pos != null) add(VideoPositionUpdatedEvent(pos));
    });
  }

  Future<void> _disposeController() async {
    _posTimer?.cancel();
    await _controller?.dispose();
    _controller = null;
  }

  /// Saves the current video position to PlaylistBloc for resume support.
  void _persistCurrentPosition() {
    if (state is! VideoReady) return;
    final s          = state as VideoReady;
    final posSeconds = s.position.inSeconds;
    if (posSeconds < 5) return;
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
