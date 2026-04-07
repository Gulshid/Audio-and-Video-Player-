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
    this.volume        = 1.0,
    this.isMuted       = false,
    this.isFullscreen  = false,
    this.playbackSpeed = 1.0,
  });

  final VideoPlayerController controller;
  final MediaItem             item;
  final bool                  isPlaying;
  final Duration              position;
  final Duration              duration;
  final double                volume;
  final bool                  isMuted;
  final bool                  isFullscreen;
  final double                playbackSpeed;

  double get progress {
    if (duration.inMilliseconds == 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  VideoReady copyWith({
    VideoPlayerController? controller,
    MediaItem?             item,
    bool?                  isPlaying,
    Duration?              position,
    Duration?              duration,
    double?                volume,
    bool?                  isMuted,
    bool?                  isFullscreen,
    double?                playbackSpeed,
  }) =>
      VideoReady(
        controller:    controller    ?? this.controller,
        item:          item          ?? this.item,
        isPlaying:     isPlaying     ?? this.isPlaying,
        position:      position      ?? this.position,
        duration:      duration      ?? this.duration,
        volume:        volume        ?? this.volume,
        isMuted:       isMuted       ?? this.isMuted,
        isFullscreen:  isFullscreen  ?? this.isFullscreen,
        playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      );

  @override
  List<Object?> get props => [
        // FIX: controller was missing — Equatable never saw controller changes.
        // Use identityHashCode so we don't compare controller internals.
        identityHashCode(controller),
        item, isPlaying, position, duration,
        volume, isMuted, isFullscreen, playbackSpeed,
      ];
}