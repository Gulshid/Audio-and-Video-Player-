import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/entities/media_item.dart';
import 'playlist_event.dart';
import 'playlist_state.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  PlaylistBloc() : super(const PlaylistInitial()) {
    on<PlaylistLoadEvent>       (_onLoad);
    on<PlaylistAddItemEvent>    (_onAdd);
    on<PlaylistAddManyEvent>    (_onAddMany);
    on<PlaylistRemoveItemEvent> (_onRemove);
    on<PlaylistReorderEvent>    (_onReorder);
    on<PlaylistToggleFavoriteEvent>(_onToggleFav);
    on<PlaylistClearEvent>      (_onClear);
    on<PlaylistUpdatePositionEvent>(_onUpdatePos);
    on<PlaylistSearchEvent>     (_onSearch);
  }

  // ── Helpers ──────────────────────────────────────────────

  Box get _box => Hive.box(AppConstants.playlistBox);

  List<MediaItem> _readAll() {
    return _box.values
        .map((e) => MediaItem.fromMap(e as Map))
        .toList();
  }

  Future<void> _persist(List<MediaItem> items) async {
    await _box.clear();
    for (final item in items) {
      await _box.put(item.id, item.toMap());
    }
  }

  // ── Event handlers ───────────────────────────────────────

  Future<void> _onLoad(
    PlaylistLoadEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    emit(const PlaylistLoading());
    try {
      if (!Hive.isBoxOpen(AppConstants.playlistBox)) {
        await Hive.openBox(AppConstants.playlistBox);
      }
      emit(PlaylistLoaded(items: _readAll()));
    } catch (e) {
      emit(PlaylistError(e.toString()));
    }
  }

  Future<void> _onAdd(
    PlaylistAddItemEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    final current = _currentItems;
    // Avoid duplicates
    if (current.any((e) => e.id == event.item.id)) return;
    final updated = [...current, event.item];
    await _persist(updated);
    emit(PlaylistLoaded(items: updated));
  }

  Future<void> _onAddMany(
    PlaylistAddManyEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    final current    = _currentItems;
    final existingIds = current.map((e) => e.id).toSet();
    final newItems   = event.items.where((e) => !existingIds.contains(e.id));
    final updated    = [...current, ...newItems];
    await _persist(updated);
    emit(PlaylistLoaded(items: updated));
  }

  Future<void> _onRemove(
    PlaylistRemoveItemEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    final updated = _currentItems.where((e) => e.id != event.id).toList();
    await _persist(updated);
    emit(PlaylistLoaded(items: updated));
  }

  Future<void> _onReorder(
    PlaylistReorderEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    final list = List<MediaItem>.from(_currentItems);
    int newIndex = event.newIndex;
    if (newIndex > event.oldIndex) newIndex--;
    final item = list.removeAt(event.oldIndex);
    list.insert(newIndex, item);
    await _persist(list);
    emit(PlaylistLoaded(items: list));
  }

  Future<void> _onToggleFav(
    PlaylistToggleFavoriteEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    final updated = _currentItems.map((e) {
      return e.id == event.id ? e.copyWith(isFavorite: !e.isFavorite) : e;
    }).toList();
    await _persist(updated);
    emit(PlaylistLoaded(items: updated));
  }

  Future<void> _onClear(
    PlaylistClearEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    await _box.clear();
    emit(const PlaylistLoaded(items: []));
  }

  Future<void> _onUpdatePos(
    PlaylistUpdatePositionEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    final updated = _currentItems.map((e) {
      return e.id == event.id
          ? e.copyWith(lastPositionSeconds: event.positionSeconds)
          : e;
    }).toList();
    await _persist(updated);
    // Emit silently without rebuilding the full UI (position updates are frequent)
    if (state is PlaylistLoaded) {
      emit((state as PlaylistLoaded).copyWith(items: updated));
    }
  }

  void _onSearch(
    PlaylistSearchEvent event,
    Emitter<PlaylistState> emit,
  ) {
    if (state is! PlaylistLoaded) return;
    final current = state as PlaylistLoaded;
    if (event.query.trim().isEmpty) {
      emit(current.copyWith(clearFilter: true, searchQuery: ''));
      return;
    }
    final q = event.query.toLowerCase();
    final filtered = current.items.where((e) {
      return e.title.toLowerCase().contains(q) ||
             (e.artist?.toLowerCase().contains(q) ?? false);
    }).toList();
    emit(current.copyWith(filtered: filtered, searchQuery: event.query));
  }

  List<MediaItem> get _currentItems {
    if (state is PlaylistLoaded) return (state as PlaylistLoaded).items;
    return [];
  }
}
