import 'package:equatable/equatable.dart';
import '../../playlist/domain/entities/media_item.dart';

enum RepeatMode { none, one, all }

abstract class AudioState extends Equatable {
  const AudioState();
  @override
  List<Object?> get props => [];
}

class AudioInitial extends AudioState {
  const AudioInitial();
}

class AudioLoading extends AudioState {
  const AudioLoading();
}

class AudioError extends AudioState {
  const AudioError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class AudioReady extends AudioState {
  const AudioReady({
    required this.currentItem,
    required this.isPlaying,
    this.position   = Duration.zero,
    this.duration   = Duration.zero,
    this.volume     = 1.0,
    this.isShuffle  = false,
    this.repeatMode = RepeatMode.none,
    this.isBuffering = false,
    this.playlist   = const [],
    this.queueIndex = 0,
  });

  final MediaItem       currentItem;
  final bool            isPlaying;
  final Duration        position;
  final Duration        duration;
  final double          volume;
  final bool            isShuffle;
  final RepeatMode      repeatMode;
  final bool            isBuffering;
  final List<MediaItem> playlist;
  final int             queueIndex;

  bool get hasPrev => queueIndex > 0;
  bool get hasNext => queueIndex < playlist.length - 1;

  /// Progress as 0.0 – 1.0 (safe — no divide-by-zero).
  double get progress {
    if (duration.inMilliseconds == 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  AudioReady copyWith({
    MediaItem?       currentItem,
    bool?            isPlaying,
    Duration?        position,
    Duration?        duration,
    double?          volume,
    bool?            isShuffle,
    RepeatMode?      repeatMode,
    bool?            isBuffering,
    List<MediaItem>? playlist,
    int?             queueIndex,
  }) =>
      AudioReady(
        currentItem: currentItem ?? this.currentItem,
        isPlaying:   isPlaying   ?? this.isPlaying,
        position:    position    ?? this.position,
        duration:    duration    ?? this.duration,
        volume:      volume      ?? this.volume,
        isShuffle:   isShuffle   ?? this.isShuffle,
        repeatMode:  repeatMode  ?? this.repeatMode,
        isBuffering: isBuffering ?? this.isBuffering,
        playlist:    playlist    ?? this.playlist,
        queueIndex:  queueIndex  ?? this.queueIndex,
      );

  @override
  List<Object?> get props => [
        currentItem, isPlaying, position, duration,
        volume, isShuffle, repeatMode, isBuffering,
        playlist, queueIndex,
      ];
}
