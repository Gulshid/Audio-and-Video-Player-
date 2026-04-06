import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/duration_formatter.dart';
import '../../bloc/audio_bloc.dart';
import '../../bloc/audio_event.dart';
import '../../bloc/audio_state.dart';

/// Seek bar + time labels for the audio player.
/// Rebuilds ONLY when position changes, using [buildWhen].
class AudioProgressBar extends StatelessWidget {
  const AudioProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<AudioBloc, AudioState>(
      // Avoid full-UI rebuilds; only redraw when position / duration changes.
      buildWhen: (prev, curr) {
        if (prev is AudioReady && curr is AudioReady) {
          return prev.position != curr.position ||
              prev.duration != curr.duration;
        }
        return prev.runtimeType != curr.runtimeType;
      },
      builder: (context, state) {
        final position = state is AudioReady ? state.position : Duration.zero;
        final duration = state is AudioReady ? state.duration : Duration.zero;

        final sliderMax = duration.inMilliseconds.toDouble();
        final sliderVal = position.inMilliseconds
            .toDouble()
            .clamp(0.0, sliderMax > 0 ? sliderMax : 1.0);

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape:
                    RoundSliderThumbShape(enabledThumbRadius: 6.r),
                overlayShape:
                    RoundSliderOverlayShape(overlayRadius: 14.r),
                trackHeight: 3.h,
              ),
              child: Slider(
                value: sliderVal,
                min:   0,
                max:   sliderMax > 0 ? sliderMax : 1.0,
                onChanged: (v) {
                  context.read<AudioBloc>().add(
                        AudioSeekEvent(
                          Duration(milliseconds: v.toInt()),
                        ),
                      );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DurationFormatter.format(position),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    DurationFormatter.format(duration),
                    style: Theme.of(context).textTheme.labelSmall,
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
