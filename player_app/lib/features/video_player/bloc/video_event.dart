import 'package:equatable/equatable.dart';

import '../../playlist/domain/entities/media_item.dart';

abstract class VideoEvent extends Equatable {
  const VideoEvent();
  @override
  List<Object?> get props => [];
}

class VideoInitializeEvent extends VideoEvent {
  const VideoInitializeEvent(this.item);
  final MediaItem item;
  @override
  List<Object?> get props => [item];
}

class VideoPlayEvent extends VideoEvent {
  const VideoPlayEvent();
}

class VideoPauseEvent extends VideoEvent {
  const VideoPauseEvent();
}

class VideoSeekEvent extends VideoEvent {
  const VideoSeekEvent(this.position);
  final Duration position;
  @override
  List<Object?> get props => [position];
}

class VideoSkipForwardEvent extends VideoEvent {
  const VideoSkipForwardEvent();
}

class VideoSkipBackwardEvent extends VideoEvent {
  const VideoSkipBackwardEvent();
}

class VideoSetVolumeEvent extends VideoEvent {
  const VideoSetVolumeEvent(this.volume);
  final double volume;
  @override
  List<Object?> get props => [volume];
}

class VideoToggleMuteEvent extends VideoEvent {
  const VideoToggleMuteEvent();
}

class VideoToggleFullscreenEvent extends VideoEvent {
  const VideoToggleFullscreenEvent();
}

class VideoSetSpeedEvent extends VideoEvent {
  const VideoSetSpeedEvent(this.speed);
  final double speed;
  @override
  List<Object?> get props => [speed];
}

class VideoDisposeEvent extends VideoEvent {
  const VideoDisposeEvent();
}

/// Internal — fired by the position timer (every 500 ms).
class VideoPositionUpdatedEvent extends VideoEvent {
  const VideoPositionUpdatedEvent(this.position, this.buffered);
  final Duration position;
  final Duration buffered;   // ← furthest buffered range end
  @override
  List<Object?> get props => [position, buffered];
}

/// Internal — fired by the controller listener when playback completes.
class VideoCompletedEvent extends VideoEvent {
  const VideoCompletedEvent();
}