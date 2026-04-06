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
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 3, vsync: this, initialIndex: 0);
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
        title: _searching ? _SearchField() : const Text('Library'),
        bottom: TabBar(
          controller: _tabs,
          labelStyle:
              TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Audio'),
            Tab(text: 'Video'),
          ],
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
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _pickFiles(context),
          ),
        ],
      ),
      body: BlocBuilder<PlaylistBloc, PlaylistState>(
        builder: (context, state) {
          if (state is PlaylistLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PlaylistError) {
            return Center(child: Text(state.message));
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

  Widget _SearchField() {
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
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        ...AppConstants.audioExtensions,
        ...AppConstants.videoExtensions,
      ],
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

    return ReorderableListView.builder(
      padding:      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      itemCount:    items.length,
      onReorder:    (o, n) => context
          .read<PlaylistBloc>()
          .add(PlaylistReorderEvent(o, n)),
      itemBuilder:  (context, i) {
        final item = items[i];
        return MediaListTile(
          key:  ValueKey(item.id),
          item: item,
          onTap: () => _play(context, item, items),
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
      context.push('/audio-player');
    } else {
      context.push('/video-player', extra: item);
    }
  }
}
