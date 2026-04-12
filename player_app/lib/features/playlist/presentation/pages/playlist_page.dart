import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../audio_player/bloc/audio_bloc.dart';
import '../../../audio_player/bloc/audio_event.dart';
import '../../bloc/playlist_bloc.dart';
import '../../bloc/playlist_event.dart';
import '../../bloc/playlist_state.dart';
import '../../domain/entities/media_item.dart';
import '../widgets/media_list_tile.dart';

class PlaylistPage extends StatefulWidget {
  /// When non-null, the Library will open pre-filtered to this type.
  final MediaType? initialFilter;

  const PlaylistPage({super.key, this.initialFilter});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length:       3,
    vsync:        this,
    initialIndex: widget.initialFilter == MediaType.audio
        ? 1
        : widget.initialFilter == MediaType.video
            ? 2
            : 0,
  );
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searching ? _buildSearchField() : const Text('Library'),
        
        bottom: PreferredSize(
  preferredSize: Size.fromHeight(56.h),
  child: Padding(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
    child: TabBar(
      controller: _tabs,
      isScrollable: true,
      tabAlignment: TabAlignment.center,
      indicator: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: Colors.white,
      unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(.6),
      labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
      padding: EdgeInsets.zero,
      labelPadding: EdgeInsets.symmetric(horizontal: 6.w),
      tabs: [
        Tab(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.library_music_rounded, size: 16.r),
                SizedBox(width: 6.w),
                const Text('All'),
              ],
            ),
          ),
        ),
        Tab(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.headphones_rounded, size: 16.r),
                SizedBox(width: 6.w),
                const Text('Audio'),
              ],
            ),
          ),
        ),
        Tab(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_rounded, size: 16.r),
                SizedBox(width: 6.w),
                const Text('Video'),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() => _searching = !_searching);
              if (!_searching) {
                _searchCtrl.clear();
                context.read<PlaylistBloc>().add(const PlaylistSearchEvent(''));
              }
            },
          ),
          // Scan device for all audio/video automatically
          IconButton(
            icon: const Icon(Icons.radar_rounded),
            tooltip: 'Scan device for media',
            onPressed: () =>
                context.read<PlaylistBloc>().add(const PlaylistScanDeviceEvent()),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Pick files manually',
            onPressed: () => _pickFiles(context),
          ),
        ],
      ),
      body: BlocConsumer<PlaylistBloc, PlaylistState>(
        listener: (context, state) {
          // Show result snackbar after scan completes
          if (state is PlaylistLoaded && state.lastScanCount != null) {
            final count = state.lastScanCount!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(count == 0
                    ? 'No new media found on device.'
                    : 'Found $count new media file${count == 1 ? '' : 's'}!'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          if (state is PlaylistError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PlaylistLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          // ── Scanning indicator ──────────────────────────
          if (state is PlaylistScanning) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 16.h),
                  Text('Scanning device for media…',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }
          if (state is PlaylistError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 48.r,
                        color: Theme.of(context).colorScheme.error),
                    SizedBox(height: 12.h),
                    Text(state.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                    SizedBox(height: 16.h),
                    FilledButton.icon(
                      onPressed: () => context
                          .read<PlaylistBloc>()
                          .add(const PlaylistLoadEvent()),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is! PlaylistLoaded) {
            return const SizedBox.shrink();
          }

          final all    = state.displayItems;
          final audio  = all.where((e) => e.type == MediaType.audio).toList();
          final video  = all.where((e) => e.type == MediaType.video).toList();

          return ResponsiveBuilder(
            builder: (context, device) {
              return TabBarView(
                controller: _tabs,
                children: [
                  _MediaList(items: all,   showEmpty: 'No media yet'),
                  _MediaList(items: audio, showEmpty: 'No audio files'),
                  _MediaList(items: video, showEmpty: 'No video files'),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Search field ─────────────────────────────────────────

  Widget _buildSearchField() {
    return TextField(
      controller:  _searchCtrl,
      autofocus:   true,
      style:       TextStyle(fontSize: 15.sp),
      decoration:  const InputDecoration(
        hintText: 'Search…',
        border:   InputBorder.none,
      ),
      onChanged: (q) =>
          context.read<PlaylistBloc>().add(PlaylistSearchEvent(q)),
    );
  }

  // ── File picker ──────────────────────────────────────────

  Future<void> _pickFiles(BuildContext ctx) async {
    // FileType.media lets the OS surface ALL audio AND video natively —
    // no manual extension whitelist needed.
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.media,
    );

    if (result == null || result.files.isEmpty) return;

    final items = result.files.map((f) {
      final ext  = p.extension(f.name).replaceFirst('.', '').toLowerCase();
      final type = AppConstants.audioExtensions.contains(ext)
          ? MediaType.audio
          : MediaType.video;
      return MediaItem(
        id:    f.path ?? f.name,
        title: p.basenameWithoutExtension(f.name),
        path:  f.path ?? '',
        type:  type,
      );
    }).toList();

    if (ctx.mounted) {
      ctx.read<PlaylistBloc>().add(PlaylistAddManyEvent(items));
    }
  }
}

// ── Reusable list widget ──────────────────────────────────────

class _MediaList extends StatelessWidget {
  const _MediaList({required this.items, required this.showEmpty});
  final List<MediaItem> items;
  final String          showEmpty;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_music_rounded,
                size: 64.r,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(.2)),
            SizedBox(height: 12.h),
            Text(showEmpty,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    // Replace your ReorderableListView.builder in _MediaList

        return ReorderableListView.builder(
          // Bottom padding: mini player height + nav bar height + safe gap,
          // so the last item is never hidden behind the floating mini player.
          padding: EdgeInsets.only(
            left:   12.w,
            right:  12.w,
            top:    8.h,
            bottom: 80.h + 10.h,
          ),
          itemCount:                items.length,
          buildDefaultDragHandles:  false,   // ← kills the long-press conflict
          onReorder: (o, n) => context
              .read<PlaylistBloc>()
              .add(PlaylistReorderEvent(o, n)),
          itemBuilder: (context, i) {
            final item = items[i];
            return MediaListTile(
              key:           ValueKey(item.id),
              item:          item,
              reorderIndex:  i,
              onTap:         () => _play(context, item, items),
              onFavoriteTap: () => context
                  .read<PlaylistBloc>()
                  .add(PlaylistToggleFavoriteEvent(item.id)),
              onDelete: () => context
                  .read<PlaylistBloc>()
                  .add(PlaylistRemoveItemEvent(item.id)),
            );
          },
        );
  }

  void _play(BuildContext context, MediaItem item, List<MediaItem> queue) {
    if (item.type == MediaType.audio) {
      context
          .read<AudioBloc>()
          .add(AudioPlayEvent(item, playlist: queue));
      Future.microtask(() { if (context.mounted) context.push('/audio-player', extra: item); });
    } else {
      context.push('/video-player', extra: item);
    }
  }
}