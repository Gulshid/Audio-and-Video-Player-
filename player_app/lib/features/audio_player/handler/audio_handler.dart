import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../playlist/domain/entities/media_item.dart' as app;

class AppAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer();

  AppAudioHandler() {
    // Forward just_audio playback events → audio_service notification
    player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Update duration in the notification when it loads
    player.durationStream.listen((dur) {
      final current = mediaItem.value;
      if (current != null && dur != null) {
        mediaItem.add(current.copyWith(duration: dur));
      }
    });

    // Notify audio_service when track completes
    player.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed) {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
        ));
      }
    });
  }

  // ── Called from AudioBloc ────────────────────────────────

  Future<Duration?> loadAndPlay(app.MediaItem item) async {
    // Push track metadata → OS notification & lock screen
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

    await player.play();
    return duration;
  }

  Uri? _artUri(String? art) {
    if (art == null) return null;
    if (art.startsWith('http')) return Uri.tryParse(art);
    return Uri.file(art); // local file path
  }

  // ── Lock-screen / notification button handlers ───────────

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop(); // dismisses the OS notification
  }

  @override
  Future<void> seek(Duration pos) => player.seek(pos);

  @override
  Future<void> skipToNext() async {
    // AudioBloc handles next-track logic via AudioNextTrackEvent.
    // Lock-screen next button fires this — forward the event via
    // a custom callback if you want full lock-screen control.
  }

  @override
  Future<void> skipToPrevious() async {
    // Same as above.
  }

  // Called when user swipes the app away from recents
  @override
  Future<void> onTaskRemoved() async {
    await player.stop();
    await super.onTaskRemoved();
  }

  // ── Map just_audio → audio_service playback state ────────

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
      androidCompactActionIndices: const [0, 1, 2], // prev / play / next
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