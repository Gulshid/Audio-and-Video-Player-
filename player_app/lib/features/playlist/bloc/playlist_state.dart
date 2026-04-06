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

class PlaylistLoaded extends PlaylistState {
  const PlaylistLoaded({
    required this.items,
    this.filtered,
    this.searchQuery = '',
  });

  /// Full list (source of truth — persisted).
  final List<MediaItem> items;

  /// Non-null while a search is active; null means "show all".
  final List<MediaItem>? filtered;

  final String searchQuery;

  /// The list the UI should render.
  List<MediaItem> get displayItems => filtered ?? items;

  List<MediaItem> get favorites =>
      items.where((e) => e.isFavorite).toList();

  PlaylistLoaded copyWith({
    List<MediaItem>? items,
    List<MediaItem>? filtered,
    String?          searchQuery,
    bool             clearFilter = false,
  }) =>
      PlaylistLoaded(
        items:       items       ?? this.items,
        filtered:    clearFilter ? null : (filtered ?? this.filtered),
        searchQuery: searchQuery ?? this.searchQuery,
      );

  @override
  List<Object?> get props => [items, filtered, searchQuery];
}

class PlaylistError extends PlaylistState {
  const PlaylistError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
