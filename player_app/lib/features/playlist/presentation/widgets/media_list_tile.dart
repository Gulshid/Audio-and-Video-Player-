import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/media_item.dart';

/// A single tile used in playlist lists for both audio and video.
///
/// Provides:
///  - Leading thumbnail / icon
///  - Title + subtitle (artist or duration)
///  - Favorite icon
///  - Trailing more-options menu
class MediaListTile extends StatelessWidget {
  const MediaListTile({
    required this.item,
    required this.onTap,
    this.onFavoriteTap,
    this.onDelete,
    this.isActive = false,
    super.key,
  });

  final MediaItem    item;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onDelete;
  final bool         isActive;

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final isAudio = item.type == MediaType.audio;

    return ListTile(
      contentPadding:
          EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      selected:      isActive,
      selectedColor: scheme.primary,
      selectedTileColor: scheme.primary.withOpacity(.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      onTap: onTap,

      // ── Leading thumbnail ──────────────────────────────
      leading: _Thumbnail(item: item, isActive: isActive),

      // ── Title & sub ────────────────────────────────────
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? scheme.primary : null,
            ),
      ),
      subtitle: Text(
        isAudio
            ? (item.artist ?? 'Unknown artist')
            : _durationLabel(item.duration),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
      ),

      // ── Trailing actions ────────────────────────────────
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Favorite
          if (onFavoriteTap != null)
            IconButton(
              iconSize: 20.r,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                item.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color:
                    item.isFavorite ? Colors.redAccent : scheme.onSurface.withOpacity(.4),
              ),
              onPressed: onFavoriteTap,
            ),

          // More options
          PopupMenuButton<String>(
            iconSize: 20.r,
            padding: EdgeInsets.zero,
            onSelected: (val) {
              if (val == 'delete' && onDelete != null) onDelete!();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline_rounded),
                  title: Text('Remove'),
                ),
              ),
            ],
          ),

          
        ],
      ),
    );
  }

  String _durationLabel(Duration? d) {
    if (d == null) return '';
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item, required this.isActive});
  final MediaItem item;
  final bool      isActive;

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final isAudio = item.type == MediaType.audio;
    final size    = 50.r;

    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        color:        isActive
            ? scheme.primary.withOpacity(.15)
            : scheme.onSurface.withOpacity(.08),
        borderRadius: BorderRadius.circular(10.r),
        image: item.albumArt != null
            ? DecorationImage(
                image: item.albumArt!.startsWith('http')
                    ? NetworkImage(item.albumArt!) as ImageProvider
                    : AssetImage(item.albumArt!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: item.albumArt == null
          ? Icon(
              isAudio
                  ? Icons.music_note_rounded
                  : Icons.play_circle_outline_rounded,
              size:  26.r,
              color: isActive ? scheme.primary : scheme.onSurface.withOpacity(.4),
            )
          : null,
    );
  }
}
