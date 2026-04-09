import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../playlist/domain/entities/media_item.dart' as app;

class AppAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer();

  StreamSubscription? _playbackEventSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _playerStateSub;

  // Cache last event so we can re-emit after loading completes.
  PlaybackEvent? _lastEvent;

  // TRUE while setFilePath/setUrl is running.
  // Blocks forwarding playing=false intermediate states to Android OS.
  // Without this, Android sees paused state during loading and — because
  // androidStopForegroundOnPause=true — sends a PAUSE media action back,
  // physically calling player.pause() right after player.play().
  // This was the root cause of AudioTrack.pause: prior state=STATE_ACTIVE.
  bool _isLoadingTrack = false;

  AppAudioHandler() {
    _playbackEventSub = player.playbackEventStream.listen((event) {
      _lastEvent = event;
      // Skip OS notification updates during the loading window.
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
    _isLoadingTrack = true;
    try {
      mediaItem.add(MediaItem(
        id:     item.path,
        title:  item.title,
        artist: item.artist ?? 'Unknown artist',
        album:  '',
        artUri: _artUri(item.albumArt),
      ));

      final Duration? duration;
      if (item.isNetwork) {
        duration = await player.setUrl(item.path);
      } else {
        duration = await player.setFilePath(item.path);
      }

      // Clear flag BEFORE play() so playing=true event reaches OS correctly.
      _isLoadingTrack = false;
      await player.play();

      // Force-emit current state in case the stream event fired before
      // we cleared _isLoadingTrack.
      if (_lastEvent != null) {
        playbackState.add(_transformEvent(_lastEvent!));
      }

      return duration;
    } catch (e) {
      _isLoadingTrack = false;
      rethrow;
    }
  }

  Uri? _artUri(String? art) {
    if (art == null) return null;
    if (art.startsWith('http')) return Uri.tryParse(art);
    return Uri.file(art);
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration pos) => player.seek(pos);

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

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