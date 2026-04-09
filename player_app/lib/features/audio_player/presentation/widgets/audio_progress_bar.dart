import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/duration_formatter.dart';
import '../../bloc/audio_bloc.dart';
import '../../bloc/audio_event.dart';
import '../../bloc/audio_state.dart';

/// Seek bar + time labels for the audio player.
///
/// FIX #1 — root cause of needle not moving on first play:
///   The original widget used [buildWhen] comparing [AudioReady.position]
///   but on first load the BLoC emits [AudioLoading] → [AudioReady].
///   When the state transitions from [AudioLoading] to [AudioReady] the
///   runtime types differ, so [buildWhen] returned true and rebuilt.
///   However the slider max was computed from [state.duration] which was
///   still Duration.zero during the brief window before the first
///   [AudioDurationUpdatedEvent] arrived — making the slider max = 0
///   and clamping sliderVal to 0 permanently.
///
///   Fix: seed [AudioReady] with the real [loadedDuration] in AudioBloc
///   (see audio_bloc.dart) AND guard the slider max here so it never
///   becomes 0 when duration IS zero (show an indeterminate state instead).
class AudioProgressBar extends StatefulWidget {
  const AudioProgressBar({super.key});

  @override
  State<AudioProgressBar> createState() => _AudioProgressBarState();
}

class _AudioProgressBarState extends State<AudioProgressBar> {
  // Track whether the user is actively dragging so we don't
  // jump the thumb back to the stream position mid-drag.
  bool   _dragging        = false;
  double _dragValue       = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<AudioBloc, AudioState>(
      buildWhen: (prev, curr) {
        // Always rebuild on type change (e.g. Loading → Ready)
        if (prev.runtimeType != curr.runtimeType) return true;
        if (prev is AudioReady && curr is AudioReady) {
          return prev.position != curr.position ||
              prev.duration != curr.duration;
        }
        return false;
      },
      builder: (context, state) {
        final ready    = state is AudioReady;
        final position = ready ? state.position : Duration.zero;
        final duration = ready ? state.duration : Duration.zero;

        // FIX #1: When duration is zero (not yet loaded) show
        // a disabled slider at 0 rather than an invalid max=0 slider.
        final hasValidDuration = duration.inMilliseconds > 0;
        final sliderMax = hasValidDuration
            ? duration.inMilliseconds.toDouble()
            : 1.0; // dummy non-zero max

        final streamVal = hasValidDuration
            ? position.inMilliseconds
                .toDouble()
                .clamp(0.0, sliderMax)
            : 0.0;

        // While dragging, show the drag thumb position; otherwise follow stream.
        final sliderVal = _dragging ? _dragValue : streamVal;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape:   RoundSliderThumbShape(enabledThumbRadius: 6.r),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 14.r),
                trackHeight:  3.5.h,
                // Style the inactive track to be more visible
                inactiveTrackColor: scheme.onSurface.withOpacity(.12),
                activeTrackColor:   scheme.primary,
                thumbColor:         scheme.primary,
                overlayColor:       scheme.primary.withOpacity(.15),
              ),
              child: Slider(
                value:   sliderVal,
                min:     0,
                max:     sliderMax,
                // Disable slider until duration is known
                onChanged: ready && hasValidDuration
                    ? (v) {
                        setState(() {
                          _dragging  = true;
                          _dragValue = v;
                        });
                      }
                    : null,
                onChangeEnd: ready && hasValidDuration
                    ? (v) {
                        setState(() => _dragging = false);
                        context.read<AudioBloc>().add(
                              AudioSeekEvent(
                                Duration(milliseconds: v.toInt()),
                              ),
                            );
                      }
                    : null,
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Show drag preview time while user is scrubbing
                  Text(
                    DurationFormatter.format(
                      _dragging
                          ? Duration(milliseconds: _dragValue.toInt())
                          : position,
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _dragging
                              ? scheme.primary
                              : scheme.onSurface.withOpacity(.55),
                          fontWeight: _dragging
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                  ),
                  Text(
                    DurationFormatter.format(duration),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withOpacity(.55),
                        ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}