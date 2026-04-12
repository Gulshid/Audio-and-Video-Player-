import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../audio_player/bloc/audio_bloc.dart';
import '../../../audio_player/bloc/audio_event.dart';
import '../../../playlist/bloc/playlist_bloc.dart';
import '../../../playlist/bloc/playlist_event.dart';
import '../../../playlist/bloc/playlist_state.dart';
import '../../../playlist/domain/entities/media_item.dart';
import '../../../playlist/presentation/widgets/media_list_tile.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: BlocBuilder<PlaylistBloc, PlaylistState>(
        builder: (context, state) {
          if (state is! PlaylistLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final favs = state.favorites;

          if (favs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 64.r,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(.2)),
                  SizedBox(height: 12.h),
                  Text('No favorites yet',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding:     EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            itemCount:   favs.length,
            itemBuilder: (context, i) {
              final item = favs[i];
              return MediaListTile(
                item: item,
                onTap: () {
                  if (item.type == MediaType.audio) {
                    context
                        .read<AudioBloc>()
                        .add(AudioPlayEvent(item, playlist: favs));
                    Future.microtask(() { if (context.mounted) context.push('/audio-player', extra: item); });
                  } else {
                    context.push('/video-player', extra: item);
                  }
                },
                onFavoriteTap: () => context
                    .read<PlaylistBloc>()
                    .add(PlaylistToggleFavoriteEvent(item.id)),
              );
            },
          );
        },
      ),
    );
  }
}
