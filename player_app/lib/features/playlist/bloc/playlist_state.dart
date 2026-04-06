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
    this.searchQuery = '',
    this.lastScanCount,
  });

  /// Full list (source of truth — persisted).
  final List<MediaItem> items;

  /// Non-null while a search is active; null means "show all".
  final List<MediaItem>? filtered;

  final String searchQuery;

  /// How many new items were added by the last scan (null = no scan yet).
  final int? lastScanCount;

  /// The list the UI should render.
  List<MediaItem> get displayItems => filtered ?? items;

  List<MediaItem> get favorites =>
      items.where((e) => e.isFavorite).toList();

  PlaylistLoaded copyWith({
    List<MediaItem>? items,
    List<MediaItem>? filtered,
    String?          searchQuery,
    int?             lastScanCount,
    bool             clearFilter = false,
  }) =>
      PlaylistLoaded(
        items:         items         ?? this.items,
        filtered:      clearFilter ? null : (filtered ?? this.filtered),
        searchQuery:   searchQuery   ?? this.searchQuery,
        lastScanCount: lastScanCount ?? this.lastScanCount,
      );

  @override
  List<Object?> get props => [items, filtered, searchQuery, lastScanCount];
}

class PlaylistError extends PlaylistState {
  const PlaylistError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
