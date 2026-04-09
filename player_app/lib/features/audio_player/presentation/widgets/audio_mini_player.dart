import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../bloc/audio_bloc.dart';
import '../../bloc/audio_event.dart';
import '../../bloc/audio_state.dart';

/// Sticky mini-player rendered above the bottom nav bar.
/// Tapping it navigates to the full audio player screen.
class AudioMiniPlayer extends StatelessWidget {
  const AudioMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioBloc, AudioState>(
      builder: (context, state) {
        if (state is! AudioReady) return const SizedBox.shrink();

        final scheme = Theme.of(context).colorScheme;
        final bloc   = context.read<AudioBloc>();

        return GestureDetector(
          onTap: () => context.push('/audio-player'),
          child: Container(
            height: AppConstants.miniPlayerHeight.h,
            margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color:        scheme.surface,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withOpacity(.10),
                  blurRadius: 12,
                  offset:     const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Progress bar at top of mini player ──────────
                _MiniProgressBar(
                  progress: state.progress,
                  color:    scheme.primary,
                ),

                // ── Main row ─────────────────────────────────────
                Expanded(
                  child: Row(
                    children: [
                      // Album art
                      _MiniAlbumArt(
                        albumArt: state.currentItem.albumArt,
                        scheme:   scheme,
                        size:     AppConstants.miniPlayerHeight.h,
                      ),

                      SizedBox(width: 12.w),

                      // Title + artist
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment:  MainAxisAlignment.center,
                          children: [
                            Text(
                              state.currentItem.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (state.currentItem.artist != null) ...[
                              SizedBox(height: 2.h),
                              Text(
                                state.currentItem.artist!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurface.withOpacity(.55),
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Prev
                      _MiniIconButton(
                        icon: Icons.skip_previous_rounded,
                        size: 22.r,
                        color: state.hasPrev
                            ? scheme.onSurface
                            : scheme.onSurface.withOpacity(.25),
                        // FIX #2: Use context.read to get bloc — avoid capturing
                        // stale bloc ref. This also means the GestureDetector
                        // for the whole row won't intercept these taps.
                        onTap: state.hasPrev
                            ? () => bloc.add(const AudioPrevTrackEvent())
                            : null,
                      ),

                      // Play / Pause
                      _MiniPlayPauseButton(
                        isPlaying: state.isPlaying,
                        color:     scheme.primary,
                        size:      28.r,
                        onTap: () => bloc.add(
                          state.isPlaying
                              ? const AudioPauseEvent()
                              : const AudioResumeEvent(),
                        ),
                      ),

                      // Next
                      _MiniIconButton(
                        icon: Icons.skip_next_rounded,
                        size: 22.r,
                        color: state.hasNext
                            ? scheme.onSurface
                            : scheme.onSurface.withOpacity(.25),
                        onTap: state.hasNext
                            ? () => bloc.add(const AudioNextTrackEvent())
                            : null,
                      ),

                      // ── FIX #2: Close button ──────────────────────
                      // Wrapped in its own GestureDetector with
                      // HitTestBehavior.opaque so it always captures
                      // the tap and never bubbles up to the parent
                      // GestureDetector (which would navigate instead).
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          // Stop bubble to parent GestureDetector
                          bloc.add(const AudioStopEvent());
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical:   8.h,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size:  18.r,
                            color: scheme.onSurface.withOpacity(.4),
                          ),
                        ),
                      ),

                      SizedBox(width: 4.w),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

/// Thin progress bar clipped to the top rounded corners of the mini player.
class _MiniProgressBar extends StatelessWidget {
  const _MiniProgressBar({required this.progress, required this.color});
  final double progress;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      child: LinearProgressIndicator(
        value:           progress.clamp(0.0, 1.0),
        minHeight:       2.5.h,
        backgroundColor: color.withOpacity(.12),
        valueColor:      AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _MiniAlbumArt extends StatelessWidget {
  const _MiniAlbumArt({
    required this.albumArt,
    required this.scheme,
    required this.size,
  });
  final String?       albumArt;
  final ColorScheme   scheme;
  final double        size;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (albumArt != null) {
      image = albumArt!.startsWith('http')
          ? NetworkImage(albumArt!) as ImageProvider
          : FileImage(File(albumArt!));
    }

    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(.15),
        borderRadius: BorderRadius.only(
          topLeft:    Radius.circular(16.r),
          bottomLeft: Radius.circular(16.r),
        ),
        image: image != null
            ? DecorationImage(image: image, fit: BoxFit.cover)
            : null,
      ),
      child: image == null
          ? Icon(Icons.music_note_rounded,
              color: scheme.primary, size: 26.r)
          : null,
    );
  }
}

/// Tap target-safe icon button for the mini player row.
class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.icon,
    required this.size,
    required this.color,
    this.onTap,
  });
  final IconData icon;
  final double   size;
  final Color    color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // FIX #2: opaque so this intercepts tap and doesn't bubble
      behavior: HitTestBehavior.opaque,
      onTap:    onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

class _MiniPlayPauseButton extends StatelessWidget {
  const _MiniPlayPauseButton({
    required this.isPlaying,
    required this.color,
    required this.size,
    required this.onTap,
  });
  final bool         isPlaying;
  final Color        color;
  final double       size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:    onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
        child: Container(
          width:  size + 8.r,
          height: size + 8.r,
          decoration: BoxDecoration(
            color:  color,
            shape:  BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color:      color.withOpacity(.30),
                blurRadius: 8,
                offset:     const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size:  size * 0.7,
          ),
        ),
      ),
    );
  }
}