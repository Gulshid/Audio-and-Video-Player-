import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../bloc/audio_bloc.dart';
import '../../bloc/audio_event.dart';
import '../../bloc/audio_state.dart';

class AudioControls extends StatelessWidget {
  const AudioControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioBloc, AudioState>(
      builder: (context, state) {
        final s         = state is AudioReady ? state : null;
        final isPlaying = s?.isPlaying ?? false;
        final hasPrev   = s?.hasPrev   ?? false;
        final hasNext   = s?.hasNext   ?? false;
        final repeat    = s?.repeatMode ?? RepeatMode.none;
        final shuffle   = s?.isShuffle ?? false;

        final bloc    = context.read<AudioBloc>();
        final primary = Theme.of(context).colorScheme.primary;
        final onSurf  = Theme.of(context).colorScheme.onSurface;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Row 1 : shuffle / skip-back / play / skip-fwd / repeat ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Shuffle
                IconButton(
                  iconSize: 24.r,
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: shuffle ? primary : onSurf.withOpacity(.4),
                  ),
                  onPressed: () => bloc.add(const AudioToggleShuffleEvent()),
                ),

                // Skip backward 10 s
                IconButton(
                  iconSize: 32.r,
                  icon: Icon(Icons.replay_10_rounded, color: onSurf),
                  onPressed: () => bloc.add(const AudioSkipBackwardEvent()),
                ),

                // Play / Pause — large central button
                GestureDetector(
                  onTap: () => bloc.add(
                    isPlaying
                        ? const AudioPauseEvent()
                        : const AudioResumeEvent(),
                  ),
                  child: Container(
                    width:  64.r,
                    height: 64.r,
                    decoration: BoxDecoration(
                      color:        primary,
                      shape:        BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:      primary.withOpacity(.35),
                          blurRadius: 16,
                          offset:     const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34.r,
                    ),
                  ),
                ),

                // Skip forward 10 s
                IconButton(
                  iconSize: 32.r,
                  icon: Icon(Icons.forward_10_rounded, color: onSurf),
                  onPressed: () => bloc.add(const AudioSkipForwardEvent()),
                ),

                // Repeat
                IconButton(
                  iconSize: 24.r,
                  icon: Icon(
                    repeat == RepeatMode.one
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: repeat != RepeatMode.none
                        ? primary
                        : onSurf.withOpacity(.4),
                  ),
                  onPressed: () => bloc.add(const AudioToggleRepeatEvent()),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            // ── Row 2 : previous track / next track ─────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 28.r,
                  icon: Icon(
                    Icons.skip_previous_rounded,
                    color: hasPrev ? onSurf : onSurf.withOpacity(.3),
                  ),
                  onPressed:
                      hasPrev ? () => bloc.add(const AudioPrevTrackEvent()) : null,
                ),
                SizedBox(width: 32.w),
                IconButton(
                  iconSize: 28.r,
                  icon: Icon(
                    Icons.skip_next_rounded,
                    color: hasNext ? onSurf : onSurf.withOpacity(.3),
                  ),
                  onPressed:
                      hasNext ? () => bloc.add(const AudioNextTrackEvent()) : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
