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

        final scheme  = Theme.of(context).colorScheme;
        final bloc    = context.read<AudioBloc>();

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
            child: Row(
              children: [
                // Album art placeholder
                Container(
                  width:  AppConstants.miniPlayerHeight.h,
                  height: AppConstants.miniPlayerHeight.h,
                  decoration: BoxDecoration(
                    color:        scheme.primary.withOpacity(.15),
                    borderRadius: BorderRadius.only(
                      topLeft:    Radius.circular(16.r),
                      bottomLeft: Radius.circular(16.r),
                    ),
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    color: scheme.primary,
                    size: 28.r,
                  ),
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
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (state.currentItem.artist != null)
                        Text(
                          state.currentItem.artist!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),

                // Prev
                  IconButton(
                    iconSize: 22.r,
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: state.hasPrev
                        ? () => bloc.add(const AudioPrevTrackEvent())
                        : null,
                  ),

                  // Play / Pause
                  IconButton(
                    iconSize: 28.r,
                    icon: Icon(
                      state.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: scheme.primary,
                    ),
                    onPressed: () => bloc.add(
                      state.isPlaying
                          ? const AudioPauseEvent()
                          : const AudioResumeEvent(),
                    ),
                  ),

                  // Next
                  IconButton(
                    iconSize: 22.r,
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: state.hasNext
                        ? () => bloc.add(const AudioNextTrackEvent())
                        : null,
                  ),

                  // ── Close / dismiss ──────────────────────────────────
                  IconButton(
                    iconSize: 20.r,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: scheme.onSurface.withOpacity(.5),
                    ),
                    onPressed: () => bloc.add(const AudioStopEvent()),
                  ),

                  SizedBox(width: 4.w),
              ],
            ),
          ),
        );
      },
    );
  }
}
