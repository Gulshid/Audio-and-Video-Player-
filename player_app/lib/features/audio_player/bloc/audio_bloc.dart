import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/constants/app_constants.dart';
import 'audio_event.dart';
import 'audio_state.dart';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  AudioBloc() : super(const AudioInitial()) {
    on<AudioPlayEvent>              (_onPlay);
    on<AudioPauseEvent>             (_onPause);
    on<AudioResumeEvent>            (_onResume);
    on<AudioSeekEvent>              (_onSeek);
    on<AudioSkipForwardEvent>       (_onSkipForward);
    on<AudioSkipBackwardEvent>      (_onSkipBackward);
    on<AudioNextTrackEvent>         (_onNext);
    on<AudioPrevTrackEvent>         (_onPrev);
    on<AudioSetVolumeEvent>         (_onVolume);
    on<AudioToggleRepeatEvent>      (_onRepeat);
    on<AudioToggleShuffleEvent>     (_onShuffle);
    on<AudioStopEvent>              (_onStop);
    on<AudioPositionUpdatedEvent>   (_onPosition);
    on<AudioDurationUpdatedEvent>   (_onDuration);
    on<AudioPlayingStateChangedEvent>(_onPlayingState);

    _subscribeToPlayer();
  }

  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<bool>?      _playSub;

  void _subscribeToPlayer() {
    _posSub  = _player.positionStream.listen(
        (pos) => add(AudioPositionUpdatedEvent(pos)));
    _durSub  = _player.durationStream.listen(
        (dur) => add(AudioDurationUpdatedEvent(dur)));
    _playSub = _player.playingStream.listen(
        (playing) => add(AudioPlayingStateChangedEvent(isPlaying: playing)));
  }

  // ── Event handlers ───────────────────────────────────────

  Future<void> _onPlay(
    AudioPlayEvent event,
    Emitter<AudioState> emit,
  ) async {
    emit(const AudioLoading());
    try {
      final item  = event.item;
      final queue = event.playlist.isEmpty ? [item] : event.playlist;
      final index = queue.indexWhere((e) => e.id == item.id).clamp(0, queue.length - 1);

      if (item.isNetwork) {
        await _player.setUrl(item.path);
      } else {
        await _player.setFilePath(item.path);
      }

      // Restore last position for resume support
      if (item.lastPositionSeconds > 0) {
        await _player.seek(item.lastPosition);
      }

      await _player.play();

      emit(AudioReady(
        currentItem: item,
        isPlaying:   true,
        duration:    _player.duration ?? Duration.zero,
        playlist:    queue,
        queueIndex:  index,
      ));
    } catch (e) {
      emit(AudioError('Failed to play: ${e.toString()}'));
    }
  }

  Future<void> _onPause(
    AudioPauseEvent event,
    Emitter<AudioState> emit,
  ) async {
    await _player.pause();
    if (state is AudioReady) {
      emit((state as AudioReady).copyWith(isPlaying: false));
    }
  }

  Future<void> _onResume(
    AudioResumeEvent event,
    Emitter<AudioState> emit,
  ) async {
    await _player.play();
    if (state is AudioReady) {
      emit((state as AudioReady).copyWith(isPlaying: true));
    }
  }

  Future<void> _onSeek(
    AudioSeekEvent event,
    Emitter<AudioState> emit,
  ) async {
    await _player.seek(event.position);
    if (state is AudioReady) {
      emit((state as AudioReady).copyWith(position: event.position));
    }
  }

  Future<void> _onSkipForward(
    AudioSkipForwardEvent event,
    Emitter<AudioState> emit,
  ) async {
    if (state is! AudioReady) return;
    final s   = state as AudioReady;
    final pos = s.position + AppConstants.seekForward;
    final clamped = pos > s.duration ? s.duration : pos;
    await _player.seek(clamped);
    emit(s.copyWith(position: clamped));
  }

  Future<void> _onSkipBackward(
    AudioSkipBackwardEvent event,
    Emitter<AudioState> emit,
  ) async {
    if (state is! AudioReady) return;
    final s   = state as AudioReady;
    final pos = s.position - AppConstants.seekBackward;
    final clamped = pos.isNegative ? Duration.zero : pos;
    await _player.seek(clamped);
    emit(s.copyWith(position: clamped));
  }

  Future<void> _onNext(
    AudioNextTrackEvent event,
    Emitter<AudioState> emit,
  ) async {
    if (state is! AudioReady) return;
    final s = state as AudioReady;
    if (!s.hasNext) return;
    final nextIndex = s.queueIndex + 1;
    add(AudioPlayEvent(s.playlist[nextIndex], playlist: s.playlist));
  }

  Future<void> _onPrev(
    AudioPrevTrackEvent event,
    Emitter<AudioState> emit,
  ) async {
    if (state is! AudioReady) return;
    final s = state as AudioReady;
    // If more than 3s in, restart current track first
    if (s.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      emit(s.copyWith(position: Duration.zero));
      return;
    }
    if (!s.hasPrev) return;
    final prevIndex = s.queueIndex - 1;
    add(AudioPlayEvent(s.playlist[prevIndex], playlist: s.playlist));
  }

  Future<void> _onVolume(
    AudioSetVolumeEvent event,
    Emitter<AudioState> emit,
  ) async {
    await _player.setVolume(event.volume.clamp(0.0, 1.0));
    if (state is AudioReady) {
      emit((state as AudioReady).copyWith(volume: event.volume));
    }
  }

  void _onRepeat(
    AudioToggleRepeatEvent event,
    Emitter<AudioState> emit,
  ) {
    if (state is! AudioReady) return;
    final s    = state as AudioReady;
    final next = RepeatMode.values[(s.repeatMode.index + 1) % RepeatMode.values.length];
    _player.setLoopMode(_loopMode(next));
    emit(s.copyWith(repeatMode: next));
  }

  void _onShuffle(
    AudioToggleShuffleEvent event,
    Emitter<AudioState> emit,
  ) {
    if (state is! AudioReady) return;
    final s = state as AudioReady;
    emit(s.copyWith(isShuffle: !s.isShuffle));
  }

  Future<void> _onStop(
    AudioStopEvent event,
    Emitter<AudioState> emit,
  ) async {
    await _player.stop();
    emit(const AudioInitial());
  }

  // ── Internal stream events ───────────────────────────────

  void _onPosition(
    AudioPositionUpdatedEvent event,
    Emitter<AudioState> emit,
  ) {
    if (state is AudioReady) {
      emit((state as AudioReady).copyWith(position: event.position));
    }
  }

  void _onDuration(
    AudioDurationUpdatedEvent event,
    Emitter<AudioState> emit,
  ) {
    if (state is AudioReady && event.duration != null) {
      emit((state as AudioReady).copyWith(duration: event.duration));
    }
  }

  void _onPlayingState(
    AudioPlayingStateChangedEvent event,
    Emitter<AudioState> emit,
  ) {
    if (state is AudioReady) {
      emit((state as AudioReady).copyWith(isPlaying: event.isPlaying));
    }
  }

  // ── Helpers ──────────────────────────────────────────────

  LoopMode _loopMode(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.none: return LoopMode.off;
      case RepeatMode.one:  return LoopMode.one;
      case RepeatMode.all:  return LoopMode.all;
    }
  }

  @override
  Future<void> close() async {
    await _posSub?.cancel();
    await _durSub?.cancel();
    await _playSub?.cancel();
    await _player.dispose();
    return super.close();
  }
}
