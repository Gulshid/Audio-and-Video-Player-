import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../audio_player/bloc/audio_bloc.dart';
import '../../../audio_player/bloc/audio_event.dart';
import '../../../playlist/bloc/playlist_bloc.dart';
import '../../../playlist/bloc/playlist_state.dart';
import '../../../playlist/domain/entities/media_item.dart';

class HomeTab extends StatelessWidget {
  /// Called when the user taps a quick-action card that should switch the
  /// bottom-nav tab (e.g. Library = index 1, Favorites = index 2).
  final void Function(int tabIndex, {MediaType? filter})? onNavigateToTab;

  const HomeTab({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ──────────────────────────────────
            Text('Good listening 🎵',
                style: Theme.of(context).textTheme.displayLarge),
            SizedBox(height: 24.h),

            // ── Quick-action cards ────────────────────────
            _QuickActions(onNavigateToTab: onNavigateToTab),
            SizedBox(height: 28.h),

            // ── Recent media ──────────────────────────────
            Text('Your library',
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 12.h),
            _RecentGrid(),
          ],
        ),
      ),
    );
  }
}

// ── Quick action cards ────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final void Function(int tabIndex, {MediaType? filter})? onNavigateToTab;
  const _QuickActions({this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _ActionCard(
          icon:  Icons.music_note_rounded,
          label: 'Audio',
          color: scheme.primary,
          // Navigate to Library tab and filter to Audio only
          onTap: () => onNavigateToTab?.call(1, filter: MediaType.audio),
        ),
        SizedBox(width: 12.w),
        _ActionCard(
          icon:  Icons.videocam_rounded,
          label: 'Video',
          color: Colors.deepOrange,
          // Navigate to Library tab and filter to Video only
          onTap: () => onNavigateToTab?.call(1, filter: MediaType.video),
        ),
        SizedBox(width: 12.w),
        _ActionCard(
          icon:  Icons.favorite_rounded,
          label: 'Favorites',
          color: Colors.pinkAccent,
          onTap: () => onNavigateToTab?.call(2),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 90.h,
          decoration: BoxDecoration(
            color:        color.withOpacity(.12),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: color.withOpacity(.25)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28.r),
              SizedBox(height: 6.h),
              Text(label,
                  style: TextStyle(
                      color:      color,
                      fontSize:   12.sp,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recent media grid ─────────────────────────────────────────

class _RecentGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaylistBloc, PlaylistState>(
      builder: (context, state) {
        if (state is! PlaylistLoaded) return const SizedBox.shrink();
        final items = state.items.take(6).toList();

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              child: Column(
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 56.r,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(.2)),
                  SizedBox(height: 12.h),
                  Text('Add media from the Library tab',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics:    const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   2,
            mainAxisSpacing:  12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1.6,
          ),
          itemCount:   items.length,
          itemBuilder: (context, i) => _MediaCard(item: items[i]),
        );
      },
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final isAudio = item.type == MediaType.audio;
    final scheme  = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (isAudio) {
          context.read<AudioBloc>().add(AudioPlayEvent(item));
          context.push('/audio-player');
        } else {
          context.push('/video-player', extra: item);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color:        scheme.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
              color: scheme.onSurface.withOpacity(.08)),
        ),
        padding: EdgeInsets.all(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:  MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              isAudio
                  ? Icons.music_note_rounded
                  : Icons.play_circle_outline_rounded,
              color: isAudio ? scheme.primary : Colors.deepOrange,
              size:  26.r,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize:   12.sp,
                        )),
                if (item.artist != null)
                  Text(item.artist!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 11.sp,
                          )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
