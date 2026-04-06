import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/entities/media_item.dart';
import 'playlist_event.dart';
import 'playlist_state.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  PlaylistBloc() : super(const PlaylistInitial()) {
    on<PlaylistLoadEvent>          (_onLoad);
    on<PlaylistAddItemEvent>       (_onAdd);
    on<PlaylistAddManyEvent>       (_onAddMany);
    on<PlaylistRemoveItemEvent>    (_onRemove);
    on<PlaylistReorderEvent>       (_onReorder);
    on<PlaylistToggleFavoriteEvent>(_onToggleFav);
    on<PlaylistClearEvent>         (_onClear);
    on<PlaylistUpdatePositionEvent>(_onUpdatePos);
    on<PlaylistSearchEvent>        (_onSearch);
    on<PlaylistScanDeviceEvent>    (_onScanDevice);
  }

  Box get _box => Hive.box(AppConstants.playlistBox);

  List<MediaItem> _readAll() =>
      _box.values.map((e) => MediaItem.fromMap(e as Map)).toList();

  /// Hive keys must be <= 255 chars. File paths can be longer, so we
  /// use a short hex digest derived from the item id.
  String _hiveKey(String id) {
    final bytes = utf8.encode(id);
    // Simple djb2-style 64-bit fold into a 16-char hex string — always <= 255.
    int h = 5381;
    for (final b in bytes) {
      h = ((h << 5) + h + b) & 0x7FFFFFFFFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(16, '0');
  }

  Future<void> _persist(List<MediaItem> items) async {
    await _box.clear();
    for (final item in items) {
      await _box.put(_hiveKey(item.id), item.toMap());
    }
  }

  Future<void> _onLoad(PlaylistLoadEvent e, Emitter<PlaylistState> emit) async {
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

  Future<void> _onAdd(PlaylistAddItemEvent event, Emitter<PlaylistState> emit) async {
    final current = _currentItems;
    if (current.any((e) => e.id == event.item.id)) return;
    final updated = [...current, event.item];
    await _persist(updated);
    emit(PlaylistLoaded(items: updated));
  }

  Future<void> _onAddMany(PlaylistAddManyEvent event, Emitter<PlaylistState> emit) async {
    final current     = _currentItems;
    final existingIds = current.map((e) => e.id).toSet();
    final newItems    = event.items.where((e) => !existingIds.contains(e.id));
    final updated     = [...current, ...newItems];
    await _persist(updated);
    emit(PlaylistLoaded(items: updated));
  }

  Future<void> _onRemove(PlaylistRemoveItemEvent event, Emitter<PlaylistState> emit) async {
    final updated = _currentItems.where((e) => e.id != event.id).toList();
    await _persist(updated);
    emit(PlaylistLoaded(items: updated));
  }

  Future<void> _onReorder(PlaylistReorderEvent event, Emitter<PlaylistState> emit) async {
    final list = List<MediaItem>.from(_currentItems);
    int newIndex = event.newIndex;
    if (newIndex > event.oldIndex) newIndex--;
    final item = list.removeAt(event.oldIndex);
    list.insert(newIndex, item);
    await _persist(list);
    emit(PlaylistLoaded(items: list));
  }

  Future<void> _onToggleFav(PlaylistToggleFavoriteEvent event, Emitter<PlaylistState> emit) async {
    final updated = _currentItems.map((e) {
      return e.id == event.id ? e.copyWith(isFavorite: !e.isFavorite) : e;
    }).toList();
    await _persist(updated);
    emit(PlaylistLoaded(items: updated));
  }

  Future<void> _onClear(PlaylistClearEvent event, Emitter<PlaylistState> emit) async {
    await _box.clear();
    emit(const PlaylistLoaded(items: []));
  }

  Future<void> _onUpdatePos(PlaylistUpdatePositionEvent event, Emitter<PlaylistState> emit) async {
    final updated = _currentItems.map((e) {
      return e.id == event.id
          ? e.copyWith(lastPositionSeconds: event.positionSeconds)
          : e;
    }).toList();
    await _persist(updated);
    if (state is PlaylistLoaded) {
      emit((state as PlaylistLoaded).copyWith(items: updated));
    }
  }

  void _onSearch(PlaylistSearchEvent event, Emitter<PlaylistState> emit) {
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

  // ── Device scan ──────────────────────────────────────────

  Future<void> _onScanDevice(
    PlaylistScanDeviceEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    emit(const PlaylistScanning());

    try {
      final found       = <MediaItem>[];
      final existingIds = _currentItems.map((e) => e.id).toSet();

      if (Platform.isAndroid || Platform.isIOS) {

        // ── Request permission ─────────────────────────────
        final ps = await PhotoManager.requestPermissionExtend();
        debugPrint('🔑 permission: $ps | hasAccess=${ps.hasAccess} isAuth=${ps.isAuth}');

        // hasAccess covers both FULL and LIMITED grants (Android 13 partial).
        // isAuth is FULL only — do NOT use isAuth here.
        if (!ps.hasAccess) {
          debugPrint('🔑 Permanently denied — opening Settings');
          await PhotoManager.openSetting();
          emit(const PlaylistError(
            'Permission denied. Grant media access in Settings, then scan again.',
          ));
          return;
        }

        // ── Audio ──────────────────────────────────────────
        debugPrint('🎵 Querying audio…');
        final audioAlbums = await PhotoManager.getAssetPathList(
          type:   RequestType.audio,
          hasAll: true,
        );
        debugPrint('🎵 ${audioAlbums.length} audio album(s)');

        for (final album in audioAlbums) {
          final count = await album.assetCountAsync;
          if (count == 0) continue;
          final assets = await album.getAssetListRange(start: 0, end: count);
          for (final asset in assets) {
            final file = await asset.originFile;
            final path = file?.path;
            if (path == null || existingIds.contains(path)) continue;
            existingIds.add(path);
            found.add(MediaItem(
              id:       path,
              title:    asset.title ?? p.basenameWithoutExtension(path),
              path:     path,
              type:     MediaType.audio,
              duration: asset.duration > 0
                  ? Duration(seconds: asset.duration.toInt())
                  : null,
            ));
          }
        }

        // ── Video ──────────────────────────────────────────
        debugPrint('🎬 Querying video…');
        final videoAlbums = await PhotoManager.getAssetPathList(
          type:   RequestType.video,
          hasAll: true,
        );
        debugPrint('🎬 ${videoAlbums.length} video album(s)');

        for (final album in videoAlbums) {
          final count = await album.assetCountAsync;
          if (count == 0) continue;
          final assets = await album.getAssetListRange(start: 0, end: count);
          for (final asset in assets) {
            final file = await asset.originFile;
            final path = file?.path;
            if (path == null || existingIds.contains(path)) continue;
            existingIds.add(path);
            found.add(MediaItem(
              id:       path,
              title:    asset.title ?? p.basenameWithoutExtension(path),
              path:     path,
              type:     MediaType.video,
              duration: asset.duration > 0
                  ? Duration(seconds: asset.duration.toInt())
                  : null,
            ));
          }
        }

      } else {
        // ── Desktop: recursive walk ────────────────────────
        final home = Platform.environment['HOME'] ??
            Platform.environment['USERPROFILE'] ?? '/';
        final allExts = {
          ...AppConstants.audioExtensions,
          ...AppConstants.videoExtensions,
        };
        await for (final entity
            in Directory(home).list(recursive: true, followLinks: false)) {
          if (entity is! File) continue;
          final ext =
              p.extension(entity.path).replaceFirst('.', '').toLowerCase();
          if (!allExts.contains(ext) || existingIds.contains(entity.path)) continue;
          found.add(MediaItem(
            id:    entity.path,
            title: p.basenameWithoutExtension(entity.path),
            path:  entity.path,
            type:  AppConstants.audioExtensions.contains(ext)
                ? MediaType.audio
                : MediaType.video,
          ));
        }
      }

      debugPrint('✅ Scan done — ${found.length} new item(s)');
      final updated = [..._currentItems, ...found];
      await _persist(updated);
      emit(PlaylistLoaded(items: updated, lastScanCount: found.length));

    } catch (e, st) {
      debugPrint('❌ Scan error: $e\n$st');
      emit(PlaylistError(e.toString()));
    }
  }
}
