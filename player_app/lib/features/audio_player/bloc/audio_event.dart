import 'package:equatable/equatable.dart';
import '../../playlist/domain/entities/media_item.dart';

abstract class AudioEvent extends Equatable {
  const AudioEvent();
  @override
  List<Object?> get props => [];
}

class AudioPlayEvent extends AudioEvent {
  const AudioPlayEvent(this.item, {this.playlist = const []});
  final MediaItem       item;
  final List<MediaItem> playlist; // optional queue context
  @override
  List<Object?> get props => [item, playlist];
}

class AudioPauseEvent extends AudioEvent {
  const AudioPauseEvent();
}

class AudioResumeEvent extends AudioEvent {
  const AudioResumeEvent();
}

class AudioSeekEvent extends AudioEvent {
  const AudioSeekEvent(this.position);
  final Duration position;
  @override
  List<Object?> get props => [position];
}

class AudioSkipForwardEvent extends AudioEvent {
  const AudioSkipForwardEvent();
}

class AudioSkipBackwardEvent extends AudioEvent {
  const AudioSkipBackwardEvent();
}

class AudioNextTrackEvent extends AudioEvent {
  const AudioNextTrackEvent();
}

class AudioPrevTrackEvent extends AudioEvent {
  const AudioPrevTrackEvent();
}

class AudioSetVolumeEvent extends AudioEvent {
  const AudioSetVolumeEvent(this.volume);
  final double volume; // 0.0 – 1.0
  @override
  List<Object?> get props => [volume];
}

class AudioToggleRepeatEvent extends AudioEvent {
  const AudioToggleRepeatEvent();
}

class AudioToggleShuffleEvent extends AudioEvent {
  const AudioToggleShuffleEvent();
}

class AudioStopEvent extends AudioEvent {
  const AudioStopEvent();
}

/// Internal — fired by just_audio stream subscription.
class AudioPositionUpdatedEvent extends AudioEvent {
  const AudioPositionUpdatedEvent(this.position);
  final Duration position;
  @override
  List<Object?> get props => [position];
}

/// Internal — fired by just_audio duration stream.
class AudioDurationUpdatedEvent extends AudioEvent {
  const AudioDurationUpdatedEvent(this.duration);
  final Duration? duration;
  @override
  List<Object?> get props => [duration];
}

/// Internal — fired by just_audio playing stream.
class AudioPlayingStateChangedEvent extends AudioEvent {
  const AudioPlayingStateChangedEvent({required this.isPlaying});
  final bool isPlaying;
  @override
  List<Object?> get props => [isPlaying];
}
