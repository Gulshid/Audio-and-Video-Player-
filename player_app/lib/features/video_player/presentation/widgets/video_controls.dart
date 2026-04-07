import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/duration_formatter.dart';
import '../../bloc/video_bloc.dart';
import '../../bloc/video_event.dart';
import '../../bloc/video_state.dart';

/// Pure controls overlay — NO internal visibility timer or GestureDetector.
/// Visibility is owned entirely by VideoPlayerPage (_showControls + Timer).
/// This widget just renders the UI when it is told to be visible.
class VideoControls extends StatelessWidget {
  const VideoControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoBloc, VideoState>(
      // Only rebuild when the relevant fields change, not on every position tick
      buildWhen: (prev, next) {
        if (prev.runtimeType != next.runtimeType) return true;
        if (next is! VideoReady) return true;
        if (prev is! VideoReady) return true;
        return prev.isPlaying     != next.isPlaying     ||
               prev.isFullscreen  != next.isFullscreen  ||
               prev.playbackSpeed != next.playbackSpeed ||
               prev.isMuted       != next.isMuted       ||
               prev.duration      != next.duration;
      },
      builder: (context, state) {
        if (state is! VideoReady) return const SizedBox.shrink();
        final bloc = context.read<VideoBloc>();

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end:   Alignment.bottomCenter,
              colors: [
                Color(0x99000000),
                Color(0x00000000),
                Color(0x00000000),
                Color(0x99000000),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Top bar ────────────────────────────────────────────────
              _TopBar(
                title:        state.item.title,
                isFullscreen: state.isFullscreen,
                onFullscreen: () =>
                    bloc.add(const VideoToggleFullscreenEvent()),
              ),

              // ── Centre play / skip ─────────────────────────────────────
              _CenterControls(
                isPlaying: state.isPlaying,
                onPlay:    () => bloc.add(const VideoPlayEvent()),
                onPause:   () => bloc.add(const VideoPauseEvent()),
                onBack:    () => bloc.add(const VideoSkipBackwardEvent()),
                onForward: () => bloc.add(const VideoSkipForwardEvent()),
              ),

              // ── Bottom seek + time ─────────────────────────────────────
              // Separate BlocBuilder so only the seek bar re-renders on
              // every position tick — the rest of the UI stays calm.
              _SeekSection(bloc: bloc),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.isFullscreen,
    required this.onFullscreen,
  });
  final String       title;
  final bool         isFullscreen;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:      Colors.white,
                fontSize:   15.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isFullscreen
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded,
              color: Colors.white,
            ),
            onPressed: onFullscreen,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Centre controls
// ─────────────────────────────────────────────────────────────────────────────

class _CenterControls extends StatelessWidget {
  const _CenterControls({
    required this.isPlaying,
    required this.onPlay,
    required this.onPause,
    required this.onBack,
    required this.onForward,
  });
  final bool         isPlaying;
  final VoidCallback onPlay, onPause, onBack, onForward;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleBtn(icon: Icons.replay_10_rounded, onTap: onBack,    size: 36.r),
        SizedBox(width: 24.w),
        _CircleBtn(
          icon:  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          onTap: isPlaying ? onPause : onPlay,
          size:  56.r,
          large: true,
        ),
        SizedBox(width: 24.w),
        _CircleBtn(icon: Icons.forward_10_rounded, onTap: onForward, size: 36.r),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.onTap,
    required this.size,
    this.large = false,
  });
  final IconData     icon;
  final VoidCallback onTap;
  final double       size;
  final bool         large;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: large ? Colors.white : Colors.white.withOpacity(.2),
        ),
        child: Icon(
          icon,
          size:  size * .5,
          color: large ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seek section — own BlocBuilder so position ticks don't rebuild the whole tree
// ─────────────────────────────────────────────────────────────────────────────

class _SeekSection extends StatelessWidget {
  const _SeekSection({required this.bloc});
  final VideoBloc bloc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        if (state is! VideoReady) return const SizedBox.shrink();

        final maxMs = state.duration.inMilliseconds.toDouble();
        final curMs = state.position.inMilliseconds
            .toDouble()
            .clamp(0.0, maxMs > 0 ? maxMs : 1.0);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor:   Colors.white,
                  inactiveTrackColor: Colors.white38,
                  thumbColor:         Colors.white,
                  overlayColor:       Colors.white24,
                  trackHeight:        2.h,
                  thumbShape:
                      RoundSliderThumbShape(enabledThumbRadius: 6.r),
                ),
                child: Slider(
                  value: curMs,
                  min:   0,
                  max:   maxMs > 0 ? maxMs : 1.0,
                  onChanged: (v) => bloc.add(
                    VideoSeekEvent(Duration(milliseconds: v.toInt())),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DurationFormatter.format(state.position),
                      style: TextStyle(
                          color: Colors.white70, fontSize: 11.sp),
                    ),
                    GestureDetector(
                      onTap: () => _pickSpeed(context, state),
                      child: Text(
                        '${state.playbackSpeed}x',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 11.sp),
                      ),
                    ),
                    Text(
                      DurationFormatter.format(state.duration),
                      style: TextStyle(
                          color: Colors.white70, fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickSpeed(BuildContext context, VideoReady state) {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Text('Playback speed',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          ...speeds.map(
            (s) => ListTile(
              title: Text('${s}x'),
              trailing: s == state.playbackSpeed
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                bloc.add(VideoSetSpeedEvent(s));
                Navigator.pop(context);
              },
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}