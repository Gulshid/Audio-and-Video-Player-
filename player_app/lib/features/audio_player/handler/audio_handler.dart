import 'dart:async';
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../playlist/domain/entities/media_item.dart' as app;

class AppAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer();

  VoidCallback? onSkipToNext;
  VoidCallback? onSkipToPrevious;

  StreamSubscription? _playbackEventSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _playerStateSub;

  PlaybackEvent? _lastEvent;

  // TRUE while loading — blocks ALL playbackState updates to the OS.
  // This prevents Android from seeing playing=false during setFilePath/setUrl
  // and sending a PAUSE media button back, which was causing the first-play
  // freeze (player.pause() firing right after player.play()).
  bool _isLoadingTrack = false;

  AppAudioHandler() {
    _playbackEventSub = player.playbackEventStream.listen((event) {
      _lastEvent = event;
      // During loading, suppress ALL state updates to the OS notification.
      // We force-emit the correct playing=true state after play() is called.
      if (!_isLoadingTrack) {
        playbackState.add(_transformEvent(event));
      }
    });

    _durationSub = player.durationStream.listen((dur) {
      final current = mediaItem.value;
      if (current != null && dur != null) {
        mediaItem.add(current.copyWith(duration: dur));
      }
    });

    _playerStateSub = player.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed) {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
        ));
      }
    });
  }

  Future<Duration?> loadAndPlay(app.MediaItem item) async {
    // Raise the guard FIRST — before setFilePath/setUrl — so that the
    // playing=false events ExoPlayer emits during codec init never reach
    // the OS notification layer (which would trigger a PAUSE action back).
    _isLoadingTrack = true;
    try {
      mediaItem.add(MediaItem(
        id:     item.path,
        title:  item.title,
        artist: item.artist ?? 'Unknown artist',
        album:  '',
        artUri: _artUri(item.albumArt),
      ));

      Duration? duration;
      if (item.isNetwork) {
        duration = await player.setUrl(item.path);
      } else if (item.path.startsWith('content://')) {
        duration = await player.setUrl(item.path);
      } else {
        duration = await player.setFilePath(item.path);
      }

      if (item.lastPositionSeconds > 0) {
        await player.seek(item.lastPosition);
      }

      // Lower the guard BEFORE play() so the playing=true event
      // flows through correctly to the OS notification.
      _isLoadingTrack = false;
      await player.play();

      // Force-emit state now that the guard is down, in case the
      // playbackEventStream fired while _isLoadingTrack was true.
      if (_lastEvent != null) {
        playbackState.add(_transformEvent(_lastEvent!));
      }

      // Best-effort: wait a short time for duration to resolve.
      // content:// and some file paths return null synchronously.
      // _onDuration in AudioBloc will patch the state if this times out.
      if (duration == null || duration == Duration.zero) {
        try {
          duration = await player.durationStream
              .where((d) => d != null && d != Duration.zero)
              .first
              .timeout(const Duration(milliseconds: 800));
        } catch (_) {}
      }

      return duration;
    } catch (e) {
      _isLoadingTrack = false;
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
      ));
      rethrow;
    }
  }

  Uri? _artUri(String? art) {
    if (art == null) return null;
    if (art.startsWith('http')) return Uri.tryParse(art);
    return Uri.file(art);
  }

  @override Future<void> play()             => player.play();
  @override Future<void> pause()            => player.pause();
  @override Future<void> seek(Duration pos) => player.seek(pos);

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  @override Future<void> skipToNext()     async => onSkipToNext?.call();
  @override Future<void> skipToPrevious() async => onSkipToPrevious?.call();

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }

  Future<void> dispose() async {
    await _playbackEventSub?.cancel();
    await _durationSub?.cancel();
    await _playerStateSub?.cancel();
    await player.dispose();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToPrevious,
        MediaAction.skipToNext,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle:      AudioProcessingState.idle,
        ProcessingState.loading:   AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready:     AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing:          player.playing,
      updatePosition:   player.position,
      bufferedPosition: player.bufferedPosition,
      speed:            player.speed,
      queueIndex:       event.currentIndex,
    );
  }
}