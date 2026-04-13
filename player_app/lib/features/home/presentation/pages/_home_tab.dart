import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:media_player/core/service/thumbnail_service.dart';

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
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1.6,
          ),
          itemCount: items.length,
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
    final isAudio   = item.type == MediaType.audio;
    final scheme    = Theme.of(context).colorScheme;
    final iconColor = isAudio ? scheme.primary : Colors.deepOrange;

    return GestureDetector(
      onTap: () {
        if (isAudio) {
          context.read<AudioBloc>().add(AudioPlayEvent(item));
          Future.microtask(() {
            if (context.mounted) context.push('/audio-player', extra: item);
          });
        } else {
          context.push('/video-player', extra: item);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Thumbnail layer ───────────────────────────
            _ThumbnailLayer(item: item, iconColor: iconColor),

            // ── Dark gradient overlay ─────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(.65),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
            ),

            // ── Text info ─────────────────────────────────
            Positioned(
              left: 10.w, right: 10.w, bottom: 8.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600)),
                  if (item.artist != null) ...[
                    SizedBox(height: 2.h),
                    Text(item.artist!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white70, fontSize: 10.sp)),
                  ],
                ],
              ),
            ),

            // ── Media-type badge ──────────────────────────
            Positioned(
              top: 8.h, right: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.45),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAudio ? Icons.music_note_rounded : Icons.videocam_rounded,
                      color: iconColor, size: 11.r,
                    ),
                    SizedBox(width: 3.w),
                    Text(isAudio ? 'Audio' : 'Video',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Thumbnail layer ────────────────────────────────────────────

class _ThumbnailLayer extends StatefulWidget {
  const _ThumbnailLayer({required this.item, required this.iconColor});
  final MediaItem item;
  final Color     iconColor;

  @override
  State<_ThumbnailLayer> createState() => _ThumbnailLayerState();
}

class _ThumbnailLayerState extends State<_ThumbnailLayer> {
  late final Future<String?> _thumbFuture;

  @override
  void initState() {
    super.initState();
    _thumbFuture = _resolveThumbnail();
  }

  Future<String?> _resolveThumbnail() async {
    final item = widget.item;

    // ── Audio: use albumArt if available ──────────────
    if (item.type == MediaType.audio) {
      return (item.albumArt != null && item.albumArt!.isNotEmpty)
          ? item.albumArt
          : null;
    }

    // ── Video: delegate to ThumbnailService ──────────
    return ThumbnailService.instance.getThumbnail(
      item.path,
      isNetwork: item.isNetwork, // ✅ use the built-in getter
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _thumbFuture,
      builder: (context, snapshot) {
        // ── Loading ───────────────────────────────────
        if (snapshot.connectionState != ConnectionState.done) {
          return _Placeholder(
            iconColor: widget.iconColor,
            showShimmer: true,
          );
        }

        final path = snapshot.data;

        // ── No thumbnail ──────────────────────────────
        if (path == null || path.isEmpty) {
          return _Placeholder(iconColor: widget.iconColor);
        }

        // ── Network image ─────────────────────────────
        if (path.startsWith('http://') || path.startsWith('https://')) {
          return Image.network(
            path,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _Placeholder(iconColor: widget.iconColor),
          );
        }

        // ── Local file (cached thumb or audio artwork) ─
        return Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _Placeholder(iconColor: widget.iconColor),
        );
      },
    );
  }
}

// ── Placeholder ────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.iconColor, this.showShimmer = false});
  final Color iconColor;
  final bool  showShimmer;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: iconColor.withOpacity(.10),
      child: showShimmer
          ? const _ShimmerBox()
          : Center(
              child: Icon(Icons.broken_image_outlined,
                  color: iconColor.withOpacity(.35), size: 32.r),
            ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.04, end: 0.15).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(color: Colors.white.withOpacity(_anim.value)),
    );
  }
}



