import 'package:equatable/equatable.dart';
import 'package:video_player/video_player.dart';

import '../../playlist/domain/entities/media_item.dart';

abstract class VideoState extends Equatable {
  const VideoState();
  @override
  List<Object?> get props => [];
}

class VideoInitial extends VideoState {
  const VideoInitial();
}

class VideoLoading extends VideoState {
  const VideoLoading();
}

class VideoError extends VideoState {
  const VideoError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class VideoReady extends VideoState {
  const VideoReady({
    required this.controller,
    required this.item,
    required this.isPlaying,
    this.position      = Duration.zero,
    this.duration      = Duration.zero,
    this.buffered      = Duration.zero,   // ← furthest buffered position
    this.volume        = 1.0,
    this.isMuted       = false,
    this.isFullscreen  = false,
    this.playbackSpeed = 1.0,
    this.hasEnded      = false,           // ← video reached end
  });

  final VideoPlayerController controller;
  final MediaItem             item;
  final bool                  isPlaying;
  final Duration              position;
  final Duration              duration;
  final Duration              buffered;
  final double                volume;
  final bool                  isMuted;
  final bool                  isFullscreen;
  final double                playbackSpeed;
  final bool                  hasEnded;

  /// 0.0 → 1.0 playback progress.
  double get progress {
    if (duration.inMilliseconds == 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// 0.0 → 1.0 buffered progress.
  double get bufferedProgress {
    if (duration.inMilliseconds == 0) return 0;
    return (buffered.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  VideoReady copyWith({
    VideoPlayerController? controller,
    MediaItem?             item,
    bool?                  isPlaying,
    Duration?              position,
    Duration?              duration,
    Duration?              buffered,
    double?                volume,
    bool?                  isMuted,
    bool?                  isFullscreen,
    double?                playbackSpeed,
    bool?                  hasEnded,
  }) =>
      VideoReady(
        controller:    controller    ?? this.controller,
        item:          item          ?? this.item,
        isPlaying:     isPlaying     ?? this.isPlaying,
        position:      position      ?? this.position,
        duration:      duration      ?? this.duration,
        buffered:      buffered      ?? this.buffered,
        volume:        volume        ?? this.volume,
        isMuted:       isMuted       ?? this.isMuted,
        isFullscreen:  isFullscreen  ?? this.isFullscreen,
        playbackSpeed: playbackSpeed ?? this.playbackSpeed,
        hasEnded:      hasEnded      ?? this.hasEnded,
      );

  @override
  List<Object?> get props => [
        identityHashCode(controller),
        item,
        isPlaying,
        position,
        duration,
        buffered,
        volume,
        isMuted,
        isFullscreen,
        playbackSpeed,
        hasEnded,
      ];
}