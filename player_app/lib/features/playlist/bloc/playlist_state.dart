import 'package:equatable/equatable.dart';
import '../domain/entities/media_item.dart';

abstract class PlaylistState extends Equatable {
  const PlaylistState();
  @override
  List<Object?> get props => [];
}

class PlaylistInitial extends PlaylistState {
  const PlaylistInitial();
}

class PlaylistLoading extends PlaylistState {
  const PlaylistLoading();
}

/// Emitted while the device MediaStore scan is running.
class PlaylistScanning extends PlaylistState {
  const PlaylistScanning();
}

class PlaylistLoaded extends PlaylistState {
  const PlaylistLoaded({
    required this.items,
    this.filtered,
    this.searchQuery    = '',
    this.lastScanCount,
    this.nowPlaying,      // ← non-null for exactly one emit; consumed by UI
  });

  /// Full list (source of truth — persisted).
  final List<MediaItem> items;

  /// Non-null while a search is active; null means "show all".
  final List<MediaItem>? filtered;

  final String searchQuery;

  /// How many new items were added by the last scan (null = no scan yet).
  final int? lastScanCount;

  /// Set by PlaylistNextEvent / PlaylistPreviousEvent for one emit so that a
  /// BlocListener on the player page can navigate to the new item.
  /// Cleared immediately by PlaylistConsumeNowPlayingEvent.
  final MediaItem? nowPlaying;

  /// The list the UI should render.
  List<MediaItem> get displayItems => filtered ?? items;

  List<MediaItem> get favorites => items.where((e) => e.isFavorite).toList();

  /// Index of [item] in the full list, or -1 if not found.
  int indexOf(String id) => items.indexWhere((e) => e.id == id);

  /// Whether there is a next item after [id] (no wrap-around check —
  /// we always wrap, but callers can use this to grey out the button
  /// if they want strict end-of-list behaviour).
  bool hasNext(String id) {
    final i = indexOf(id);
    return i >= 0 && i < items.length - 1;
  }

  bool hasPrevious(String id) {
    final i = indexOf(id);
    return i > 0;
  }

  PlaylistLoaded copyWith({
    List<MediaItem>? items,
    List<MediaItem>? filtered,
    String?          searchQuery,
    int?             lastScanCount,
    bool             clearFilter    = false,
    MediaItem?       nowPlaying,
    bool             clearNowPlaying = false,
  }) =>
      PlaylistLoaded(
        items:         items         ?? this.items,
        filtered:      clearFilter   ? null : (filtered ?? this.filtered),
        searchQuery:   searchQuery   ?? this.searchQuery,
        lastScanCount: lastScanCount ?? this.lastScanCount,
        nowPlaying:    clearNowPlaying ? null : (nowPlaying ?? this.nowPlaying),
      );

  @override
  List<Object?> get props =>
      [items, filtered, searchQuery, lastScanCount, nowPlaying];
}

class PlaylistError extends PlaylistState {
  const PlaylistError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}