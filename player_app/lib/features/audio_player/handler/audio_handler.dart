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

  bool _isLoadingTrack = false;

  AppAudioHandler() {
    _playbackEventSub = player.playbackEventStream.listen((event) {
      _lastEvent = event;
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

  /// Loads and starts playback.
  ///
  /// KEY FIX: Duration polling (the 800 ms timeout) is removed from this
  /// method. It was the primary cause of the first-play freeze — it blocked
  /// the entire bloc event-handler for up to 800 ms, preventing any UI
  /// updates. Duration is now delivered asynchronously through the
  /// durationStream subscription in AudioBloc (_onDuration), which patches
  /// AudioReady.duration the moment it becomes available without blocking.
  Future<Duration?> loadAndPlay(app.MediaItem item) async {
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

      _isLoadingTrack = false;
      await player.play();

      if (_lastEvent != null) {
        playbackState.add(_transformEvent(_lastEvent!));
      }

      // Return whatever the platform resolved synchronously (may be null).
      // AudioBloc's _onDuration subscription will deliver the real value
      // asynchronously — no blocking wait here.
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
