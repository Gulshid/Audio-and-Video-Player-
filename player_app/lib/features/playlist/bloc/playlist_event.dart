import 'package:equatable/equatable.dart';
import '../domain/entities/media_item.dart';

abstract class PlaylistEvent extends Equatable {
  const PlaylistEvent();
  @override
  List<Object?> get props => [];
}

/// Load saved playlist from local storage on startup.
class PlaylistLoadEvent extends PlaylistEvent {
  const PlaylistLoadEvent();
}

/// Add a single item to the playlist.
class PlaylistAddItemEvent extends PlaylistEvent {
  const PlaylistAddItemEvent(this.item);
  final MediaItem item;
  @override
  List<Object?> get props => [item];
}

/// Add multiple items at once (e.g. import folder).
class PlaylistAddManyEvent extends PlaylistEvent {
  const PlaylistAddManyEvent(this.items);
  final List<MediaItem> items;
  @override
  List<Object?> get props => [items];
}

/// Remove an item by id.
class PlaylistRemoveItemEvent extends PlaylistEvent {
  const PlaylistRemoveItemEvent(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

/// Reorder items (drag-and-drop).
class PlaylistReorderEvent extends PlaylistEvent {
  const PlaylistReorderEvent(this.oldIndex, this.newIndex);
  final int oldIndex;
  final int newIndex;
  @override
  List<Object?> get props => [oldIndex, newIndex];
}

/// Toggle the favorite flag for an item.
class PlaylistToggleFavoriteEvent extends PlaylistEvent {
  const PlaylistToggleFavoriteEvent(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

/// Clear the entire playlist.
class PlaylistClearEvent extends PlaylistEvent {
  const PlaylistClearEvent();
}

/// Update the last-played position for resume support.
class PlaylistUpdatePositionEvent extends PlaylistEvent {
  const PlaylistUpdatePositionEvent(this.id, this.positionSeconds);
  final String id;
  final int    positionSeconds;
  @override
  List<Object?> get props => [id, positionSeconds];
}

/// Filter the visible list by query string.
class PlaylistSearchEvent extends PlaylistEvent {
  const PlaylistSearchEvent(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

/// Scan the device storage for all audio and video files.
class PlaylistScanDeviceEvent extends PlaylistEvent {
  const PlaylistScanDeviceEvent();
}