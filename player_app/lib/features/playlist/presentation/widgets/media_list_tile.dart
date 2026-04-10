import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:media_player/core/service/thumnail_service.dart';

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

class _Thumbnail extends StatefulWidget {          // ← StatefulWidget now
  const _Thumbnail({required this.item, required this.isActive});
  final MediaItem item;
  final bool      isActive;

  @override
  State<_Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends State<_Thumbnail> {
  Future<String?>? _thumbFuture;

  @override
  void initState() {
    super.initState();
    // Only generate for video — audio already has albumArt from metadata
    if (widget.item.type == MediaType.video && widget.item.albumArt == null) {
      _thumbFuture = ThumbnailService.instance.getThumbnail(
        widget.item.path,
        isNetwork: widget.item.isNetwork,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final isAudio = widget.item.type == MediaType.audio;
    final size    = 50.r;

    // ── Audio or item already has albumArt — original logic unchanged ──
    if (isAudio || widget.item.albumArt != null) {
      return _shell(
        context, size, scheme,
        child: widget.item.albumArt == null
            ? Icon(Icons.music_note_rounded,
                size: 26.r,
                color: widget.isActive
                    ? scheme.primary
                    : scheme.onSurface.withOpacity(.4))
            : null,
        image: widget.item.albumArt != null
            ? (widget.item.albumArt!.startsWith('http')
                ? NetworkImage(widget.item.albumArt!) as ImageProvider
                : FileImage(File(widget.item.albumArt!)))
            : null,
      );
    }

    // ── Video — async thumbnail ────────────────────────────────────────
    return FutureBuilder<String?>(
      future: _thumbFuture,
      builder: (context, snap) {
        ImageProvider? image;
        if (snap.connectionState == ConnectionState.done && snap.data != null) {
          image = FileImage(File(snap.data!));
        }

        return _shell(
          context, size, scheme,
          image: image,
          child: image == null
              ? snap.connectionState != ConnectionState.done
                  // Still loading — small spinner
                  ? SizedBox(
                      width:  18.r,
                      height: 18.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: scheme.onSurface.withOpacity(.3),
                      ),
                    )
                  // Failed / network stream — fallback icon
                  : Icon(Icons.play_circle_outline_rounded,
                      size:  26.r,
                      color: widget.isActive
                          ? scheme.primary
                          : scheme.onSurface.withOpacity(.4))
              : null,
        );
      },
    );
  }

  /// Shared container so shape/color/radius stay consistent
  Widget _shell(
    BuildContext context,
    double size,
    ColorScheme scheme, {
    Widget?        child,
    ImageProvider? image,
  }) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        color: widget.isActive
            ? scheme.primary.withOpacity(.15)
            : scheme.onSurface.withOpacity(.08),
        borderRadius: BorderRadius.circular(10.r),
        image: image != null
            ? DecorationImage(image: image, fit: BoxFit.cover)
            : null,
      ),
      child: child != null ? Center(child: child) : null,
    );
  }
}