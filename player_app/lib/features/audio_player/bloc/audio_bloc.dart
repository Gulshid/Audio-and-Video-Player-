import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:media_player/features/audio_player/handler/audio_handler.dart';

import '../../../core/constants/app_constants.dart';
import '../../playlist/bloc/playlist_bloc.dart';
import '../../playlist/bloc/playlist_event.dart';
import 'audio_event.dart';
import 'audio_state.dart';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  AudioBloc({
    required AppAudioHandler handler,
    PlaylistBloc? playlistBloc,
  })  : _handler = handler,
        _playlistBloc = playlistBloc,
        super(const AudioInitial()) {
    on<AudioPlayEvent>               (_onPlay);
    on<AudioPauseEvent>              (_onPause);
    on<AudioResumeEvent>             (_onResume);
    on<AudioSeekEvent>               (_onSeek);
    on<AudioSkipForwardEvent>        (_onSkipForward);
    on<AudioSkipBackwardEvent>       (_onSkipBackward);
    on<AudioNextTrackEvent>          (_onNext);
    on<AudioPrevTrackEvent>          (_onPrev);
    on<AudioSetVolumeEvent>          (_onVolume);
    on<AudioToggleRepeatEvent>       (_onRepeat);
    on<AudioToggleShuffleEvent>      (_onShuffle);
    on<AudioStopEvent>               (_onStop);
    on<AudioPositionUpdatedEvent>    (_onPosition);
    on<AudioDurationUpdatedEvent>    (_onDuration);
    on<AudioPlayingStateChangedEvent>(_onPlayingState);
    on<AudioTrackCompletedEvent>     (_onTrackCompleted);

    _subscribeToPlayer();
  }

  final AppAudioHandler _handler;
  final PlaylistBloc?   _playlistBloc;
  final Random          _random = Random();

  AudioPlayer get _player => _handler.player;

  final Set<int> _shufflePlayed = {};

  bool _isStopping = false;

  StreamSubscription<Duration>?    _posSub;
  StreamSubscription<Duration?>?   _durSub;
  StreamSubscription<bool>?        _playSub;
  StreamSubscription<PlayerState>? _stateSub;

  void _subscribeToPlayer() {
    _posSub = _player.positionStream.listen(
      (pos) { if (!isClosed) add(AudioPositionUpdatedEvent(pos)); },
      onError: (_) {},
    );
    _durSub = _player.durationStream.listen(
      (dur) { if (!isClosed) add(AudioDurationUpdatedEvent(dur)); },
      onError: (_) {},
    );
    _playSub = _player.playingStream.listen(
      (playing) {
        if (!isClosed) add(AudioPlayingStateChangedEvent(isPlaying: playing));
      },
      onError: (_) {},
    );
    _stateSub = _player.playerStateStream.listen(
      (ps) {
        if (ps.processingState == ProcessingState.completed) {
          if (!isClosed) add(const AudioTrackCompletedEvent());
        }
      },
      onError: (_) {},
    );
  }

  // ── Event handlers ───────────────────────────────────────

  Future<void> _onPlay(AudioPlayEvent event, Emitter<AudioState> emit) async {
    emit(const AudioLoading());
    try {
      final item  = event.item;
      final queue = event.playlist.isEmpty ? [item] : event.playlist;
      final index = queue
          .indexWhere((e) => e.id == item.id)
          .clamp(0, queue.length - 1);

      _persistCurrentPosition();

      // Re-subscribe if subscriptions were cancelled by a prior stop.
      if (_posSub == null) _subscribeToPlayer();

      // AppAudioHandler.loadAndPlay() now guards the OS notification
      // internally (_isLoadingTrack flag), so we don't need any flag here.
      final loadedDuration = await _handler.loadAndPlay(item);

      if (item.lastPositionSeconds > 0) {
        await _player.seek(item.lastPosition);
      }

      _shufflePlayed
        ..clear()
        ..add(index);

      emit(AudioReady(
        currentItem: item,
        isPlaying:   true,
        duration:    loadedDuration ?? Duration.zero,
        position:    item.lastPositionSeconds > 0
            ? item.lastPosition
            : Duration.zero,
        playlist:    queue,
        queueIndex:  index,
      ));
    } catch (e) {
      emit(AudioError('Failed to play: ${e.toString()}'));
    }
  }

  Future<void> _onPause(AudioPauseEvent _, Emitter<AudioState> emit) async {
    await _handler.pause();
    if (state is AudioReady) {
      emit((state as AudioReady).copyWith(isPlaying: false));
    }
  }

  Future<void> _onResume(AudioResumeEvent _, Emitter<AudioState> emit) async {
    await _handler.play();
    if (state is AudioReady) {
      emit((state as AudioReady).copyWith(isPlaying: true));
    }
  }

  Future<void> _onSeek(AudioSeekEvent event, Emitter<AudioState> emit) async {
    await _handler.seek(event.position);
    if (state is AudioReady) {
      emit((state as AudioReady).copyWith(position: event.position));
    }
  }

  Future<void> _onSkipForward(
      AudioSkipForwardEvent _, Emitter<AudioState> emit) async {
    if (state is! AudioReady) return;
    final s       = state as AudioReady;
    final pos     = s.position + AppConstants.seekForward;
    final clamped = pos > s.duration ? s.duration : pos;
    await _handler.seek(clamped);
    emit(s.copyWith(position: clamped));
  }

  Future<void> _onSkipBackward(
      AudioSkipBackwardEvent _, Emitter<AudioState> emit) async {
    if (state is! AudioReady) return;
    final s       = state as AudioReady;
    final pos     = s.position - AppConstants.seekBackward;
    final clamped = pos.isNegative ? Duration.zero : pos;
    await _handler.seek(clamped);
    emit(s.copyWith(position: clamped));
  }

  Future<void> _onNext(AudioNextTrackEvent _, Emitter<AudioState> emit) async {
    if (state is! AudioReady) return;
    final s = state as AudioReady;
    _persistCurrentPosition();
    final nextIndex = _nextIndex(s);
    if (nextIndex == null) return;
    add(AudioPlayEvent(s.playlist[nextIndex], playlist: s.playlist));
  }

  Future<void> _onPrev(AudioPrevTrackEvent _, Emitter<AudioState> emit) async {
    if (state is! AudioReady) return;
    final s = state as AudioReady;
    if (s.position.inSeconds > 3) {
      await _handler.seek(Duration.zero);
      emit(s.copyWith(position: Duration.zero));
      return;
    }
    if (!s.hasPrev) return;
    _persistCurrentPosition();
    add(AudioPlayEvent(s.playlist[s.queueIndex - 1], playlist: s.playlist));
  }

  Future<void> _onVolume(
      AudioSetVolumeEvent event, Emitter<AudioState> emit) async {
    await _player.setVolume(event.volume.clamp(0.0, 1.0));
    if (state is AudioReady) {
      emit((state as AudioReady).copyWith(volume: event.volume));
    }
  }

  void _onRepeat(AudioToggleRepeatEvent _, Emitter<AudioState> emit) {
    if (state is! AudioReady) return;
    final s    = state as AudioReady;
    final next = RepeatMode
        .values[(s.repeatMode.index + 1) % RepeatMode.values.length];
    _player.setLoopMode(_loopMode(next));
    emit(s.copyWith(repeatMode: next));
  }

  void _onShuffle(AudioToggleShuffleEvent _, Emitter<AudioState> emit) {
    if (state is! AudioReady) return;
    final s          = state as AudioReady;
    final newShuffle = !s.isShuffle;
    if (newShuffle) {
      _shufflePlayed
        ..clear()
        ..add(s.queueIndex);
    }
    emit(s.copyWith(isShuffle: newShuffle));
  }

  Future<void> _onStop(AudioStopEvent _, Emitter<AudioState> emit) async {
    if (_isStopping) return;
    _isStopping = true;
    try {
      _persistCurrentPosition();

      // Cancel subs BEFORE stop() so no events fire while tearing down.
      await _posSub?.cancel();
      await _durSub?.cancel();
      await _playSub?.cancel();
      await _stateSub?.cancel();
      _posSub   = null;
      _durSub   = null;
      _playSub  = null;
      _stateSub = null;

      await _handler.stop();
      emit(const AudioInitial());
    } catch (e) {
      debugPrint('AudioBloc stop error: $e');
      emit(const AudioInitial());
    } finally {
      _isStopping = false;
    }
  }

  Future<void> _onTrackCompleted(
    AudioTrackCompletedEvent _,
    Emitter<AudioState> emit,
  ) async {
    if (state is! AudioReady) return;
    final s = state as AudioReady;

    if (s.repeatMode == RepeatMode.one) {
      await _handler.seek(Duration.zero);
      await _handler.play();
      return;
    }

    _persistCurrentPosition();
    final nextIndex = _nextIndex(s);

    if (nextIndex == null) {
      emit(s.copyWith(isPlaying: false, position: s.duration));
      return;
    }

    add(AudioPlayEvent(s.playlist[nextIndex], playlist: s.playlist));
  }

  // ── Internal stream event handlers ───────────────────────

  void _onPosition(AudioPositionUpdatedEvent event, Emitter<AudioState> emit) {
    if (state is! AudioReady) return;
    final s       = state as AudioReady;
    final clamped = s.duration.inMilliseconds > 0 &&
            event.position > s.duration
        ? s.duration
        : event.position;
    emit(s.copyWith(position: clamped));
  }

  void _onDuration(AudioDurationUpdatedEvent event, Emitter<AudioState> emit) {
    if (event.duration == null || event.duration == Duration.zero) return;
    if (state is AudioReady) {
      emit((state as AudioReady).copyWith(duration: event.duration));
    }
  }

  // KEY FIX: Use _player.playing (actual player state) as ground truth
  // instead of event.isPlaying.
  //
  // Why: Events queued in the bloc during loadAndPlay() (e.g. playing=false
  // from setFilePath) are processed AFTER _onPlay() finishes — at which
  // point any _isLoadingTrack flag in this bloc is already cleared.
  // By reading _player.playing directly we always reflect the real state,
  // regardless of when the event was originally generated.
  void _onPlayingState(
      AudioPlayingStateChangedEvent event, Emitter<AudioState> emit) {
    if (state is! AudioReady) return;
    // Use actual player state, not the (possibly stale) event value.
    emit((state as AudioReady).copyWith(isPlaying: _player.playing));
  }

  // ── Shuffle / next-index logic ───────────────────────────

  int? _nextIndex(AudioReady s) {
    final queue = s.playlist;
    if (queue.isEmpty) return null;

    if (s.isShuffle) {
      final remaining = List.generate(queue.length, (i) => i)
          .where((i) => !_shufflePlayed.contains(i))
          .toList();

      if (remaining.isEmpty) {
        if (s.repeatMode == RepeatMode.all) {
          _shufflePlayed.clear();
          final next = _random.nextInt(queue.length);
          _shufflePlayed.add(next);
          return next;
        }
        return null;
      }

      final next = remaining[_random.nextInt(remaining.length)];
      _shufflePlayed.add(next);
      return next;
    }

    if (s.queueIndex < queue.length - 1) return s.queueIndex + 1;
    if (s.repeatMode == RepeatMode.all) return 0;
    return null;
  }

  // ── Position persistence ─────────────────────────────────

  void _persistCurrentPosition() {
    if (state is! AudioReady) return;
    final s          = state as AudioReady;
    final posSeconds = s.position.inSeconds;
    if (posSeconds < 5) return;
    _playlistBloc?.add(
      PlaylistUpdatePositionEvent(s.currentItem.id, posSeconds),
    );
    debugPrint('💾 Saved ${posSeconds}s for "${s.currentItem.title}"');
  }

  LoopMode _loopMode(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.none: return LoopMode.off;
      case RepeatMode.one:  return LoopMode.one;
      case RepeatMode.all:  return LoopMode.off;
    }
  }

  @override
  Future<void> close() async {
    _persistCurrentPosition();
    await _posSub?.cancel();
    await _durSub?.cancel();
    await _playSub?.cancel();
    await _stateSub?.cancel();
    await _player.dispose();
    return super.close();
  }
}