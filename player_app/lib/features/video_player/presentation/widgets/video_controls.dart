import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/duration_formatter.dart';
import '../../../playlist/bloc/playlist_bloc.dart';
import '../../../playlist/bloc/playlist_event.dart';
import '../../../playlist/bloc/playlist_state.dart';
import '../../bloc/video_bloc.dart';
import '../../bloc/video_event.dart';
import '../../bloc/video_state.dart';
import '../pages/video_player_page.dart';


enum _FitMode { fit, fill, stretch }

extension _FitModeX on _FitMode {
  IconData get icon => switch (this) {
        _FitMode.fit     => Icons.fit_screen_rounded,
        _FitMode.fill    => Icons.crop_rounded,
        _FitMode.stretch => Icons.open_in_full_rounded,
      };

  String get label => switch (this) {
        _FitMode.fit     => 'Fit',
        _FitMode.fill    => 'Fill',
        _FitMode.stretch => 'Stretch',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// VideoControls
// ─────────────────────────────────────────────────────────────────────────────

class VideoControls extends StatefulWidget {
  const VideoControls({
    required this.locked,
    required this.onToggleLock,
    required this.fitMode,
    required this.onCycleFitMode,
    /// Called when the user taps the translucent background of the controls
    /// overlay (i.e. anywhere that isn't a button).  The page uses this to
    /// dismiss / toggle control visibility so taps never fall through to the
    /// underlying video-surface GestureDetector.
    required this.onDismiss,
    super.key,
  });

  final VideoFitMode fitMode;
  final VoidCallback onCycleFitMode;
  final bool         locked;
  final VoidCallback onToggleLock;
  final VoidCallback onDismiss;

  @override
  State<VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls> {

  // ── Map the page-level VideoFitMode → local _FitMode for icon / label ─────
  // BUG FIX: previously the controls maintained their own local _fitMode state
  // and called setState() on cycle, but never called widget.onCycleFitMode().
  // The video surface therefore never received the updated BoxFit and the fit
  // button had zero effect.  Now the display is driven purely by the parent's
  // widget.fitMode, and cycling delegates entirely to widget.onCycleFitMode().
  _FitMode get _displayFit => switch (widget.fitMode) {
        VideoFitMode.fit     => _FitMode.fit,
        VideoFitMode.fill    => _FitMode.fill,
        VideoFitMode.stretch => _FitMode.stretch,
      };

  @override
  Widget build(BuildContext context) {
    // Locked state: only show the unlock button.
    if (widget.locked) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: _LockButton(locked: true, onTap: widget.onToggleLock),
        ),
      );
    }

    return BlocBuilder<VideoBloc, VideoState>(
      // Only rebuild for non-positional changes — the seek bar has its own
      // BlocBuilder that handles the 500 ms position ticks.
      buildWhen: (prev, next) {
        if (prev.runtimeType != next.runtimeType) return true;
        if (next is! VideoReady) return true;
        if (prev is! VideoReady) return true;
        return prev.isPlaying     != next.isPlaying     ||
               prev.isFullscreen  != next.isFullscreen  ||
               prev.playbackSpeed != next.playbackSpeed ||
               prev.isMuted       != next.isMuted       ||
               prev.volume        != next.volume        ||
               prev.duration      != next.duration      ||
               prev.hasEnded      != next.hasEnded;
      },
      builder: (context, state) {
        if (state is! VideoReady) return const SizedBox.shrink();
        final bloc         = context.read<VideoBloc>();
        final playlistBloc = context.read<PlaylistBloc>();

        final playlistState = playlistBloc.state;
        final multiItem = playlistState is PlaylistLoaded &&
            playlistState.items.length > 1;

        // ── BUG FIX: wrap in GestureDetector with opaque behaviour ──────────
        // Previously the controls overlay used HitTestBehavior.translucent in
        // _VideoSurface, so every button press also fired the underlying
        // onVideoTap callback, instantly hiding the controls after any
        // interaction.  Now the gradient container itself absorbs taps:
        //   • Tapping a button  → Flutter delivers to the inner GestureDetector
        //     (the button); the background GestureDetector does NOT fire.
        //   • Tapping the empty gradient area → background GestureDetector
        //     fires widget.onDismiss, letting the page toggle visibility.
        //   • The video-surface GestureDetector is never reached while controls
        //     are visible because IgnorePointer + this opaque detector block it.
        return GestureDetector(
          onTap: widget.onDismiss,
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topCenter,
                end:    Alignment.bottomCenter,
                colors: [
                  Color(0xCC000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xCC000000),
                ],
                stops: [0.0, 0.28, 0.65, 1.0],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Top bar ────────────────────────────────────────────────
                _TopBar(
                  title:        state.item.title,
                  isFullscreen: state.isFullscreen,
                  locked:       widget.locked,
                  onFullscreen: () =>
                      bloc.add(const VideoToggleFullscreenEvent()),
                  onToggleLock: widget.onToggleLock,
                ),

                // ── Centre controls ────────────────────────────────────────
                _CenterControls(
                  isPlaying:  state.isPlaying,
                  hasEnded:   state.hasEnded,
                  multiItem:  multiItem,
                  onPlay:     () => bloc.add(const VideoPlayEvent()),
                  onPause:    () => bloc.add(const VideoPauseEvent()),
                  onBack:     () => bloc.add(const VideoSkipBackwardEvent()),
                  onForward:  () => bloc.add(const VideoSkipForwardEvent()),
                  onPrevious: () => playlistBloc
                      .add(PlaylistPreviousEvent(state.item.id)),
                  onNext:     () => playlistBloc
                      .add(PlaylistNextEvent(state.item.id)),
                ),

                // ── Bottom: seek + action strip ────────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SeekSection(bloc: bloc),
                    _ActionStrip(
                      isMuted:       state.isMuted,
                      volume:        state.volume,
                      playbackSpeed: state.playbackSpeed,
                      // BUG FIX: was passing a local _fitMode that was never
                      // synced with the parent — now derived from widget.fitMode.
                      fitMode:       _displayFit,
                      bloc:          bloc,
                      // BUG FIX: was calling local setState which updated the
                      // local icon but never told the page to change BoxFit.
                      // Now delegates directly to the parent callback.
                      onCycleFit:    widget.onCycleFitMode,
                    ),
                  ],
                ),
              ],
            ),
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
    required this.locked,
    required this.onFullscreen,
    required this.onToggleLock,
  });

  final String       title;
  final bool         isFullscreen;
  final bool         locked;
  final VoidCallback onFullscreen;
  final VoidCallback onToggleLock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
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
                fontSize:   14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _LockButton(locked: locked, onTap: onToggleLock),
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
// Lock button
// ─────────────────────────────────────────────────────────────────────────────

class _LockButton extends StatelessWidget {
  const _LockButton({required this.locked, required this.onTap});
  final bool         locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: locked
              ? Colors.white.withOpacity(0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          locked ? Icons.lock_rounded : Icons.lock_open_rounded,
          color: Colors.white,
          size:  22.r,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Centre controls — prev / skip-back / play-pause / skip-forward / next
// ─────────────────────────────────────────────────────────────────────────────

class _CenterControls extends StatelessWidget {
  const _CenterControls({
    required this.isPlaying,
    required this.hasEnded,
    required this.multiItem,
    required this.onPlay,
    required this.onPause,
    required this.onBack,
    required this.onForward,
    required this.onPrevious,
    required this.onNext,
  });

  final bool         isPlaying;
  final bool         hasEnded;
  final bool         multiItem;
  final VoidCallback onPlay, onPause, onBack, onForward;
  final VoidCallback onPrevious, onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavBtn(
          icon:    Icons.skip_previous_rounded,
          onTap:   onPrevious,
          enabled: multiItem,
          size:    36.r,
        ),
        SizedBox(width: 12.w),
        _SeekIconBtn(icon: Icons.replay_10_rounded,   onTap: onBack,    size: 42.r),
        SizedBox(width: 20.w),
        _PlayPauseBtn(
          isPlaying: isPlaying,
          hasEnded:  hasEnded,
          onPlay:    onPlay,
          onPause:   onPause,
        ),
        SizedBox(width: 20.w),
        _SeekIconBtn(icon: Icons.forward_10_rounded,  onTap: onForward, size: 42.r),
        SizedBox(width: 12.w),
        _NavBtn(
          icon:    Icons.skip_next_rounded,
          onTap:   onNext,
          enabled: multiItem,
          size:    36.r,
        ),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.size,
  });
  final IconData     icon;
  final VoidCallback onTap;
  final bool         enabled;
  final double       size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width:  size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(enabled ? 0.15 : 0.06),
        ),
        child: Icon(
          icon,
          size:  size * .55,
          color: Colors.white.withOpacity(enabled ? 1.0 : 0.35),
        ),
      ),
    );
  }
}

class _PlayPauseBtn extends StatelessWidget {
  const _PlayPauseBtn({
    required this.isPlaying,
    required this.hasEnded,
    required this.onPlay,
    required this.onPause,
  });
  final bool         isPlaying;
  final bool         hasEnded;
  final VoidCallback onPlay, onPause;

  IconData get _icon {
    if (hasEnded)  return Icons.replay_rounded;
    if (isPlaying) return Icons.pause_rounded;
    return Icons.play_arrow_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPlaying ? onPause : onPlay,
      child: Container(
        width:  64.r,
        height: 64.r,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Icon(_icon, size: 36.r, color: Colors.black87),
      ),
    );
  }
}

class _SeekIconBtn extends StatelessWidget {
  const _SeekIconBtn({
    required this.icon,
    required this.onTap,
    required this.size,
  });
  final IconData     icon;
  final VoidCallback onTap;
  final double       size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
        ),
        child: Icon(icon, size: size * .55, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seek section — buffered track, drag thumb, time labels
// ─────────────────────────────────────────────────────────────────────────────

class _SeekSection extends StatefulWidget {
  const _SeekSection({required this.bloc});
  final VideoBloc bloc;

  @override
  State<_SeekSection> createState() => _SeekSectionState();
}

class _SeekSectionState extends State<_SeekSection> {
  bool   _dragging  = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        if (state is! VideoReady) return const SizedBox.shrink();

        final maxMs     = state.duration.inMilliseconds.toDouble();
        final curMs     = state.position.inMilliseconds
            .toDouble()
            .clamp(0.0, maxMs > 0 ? maxMs : 1.0);
        final buffMs    = state.buffered.inMilliseconds.toDouble();
        final sliderVal = _dragging ? _dragValue : curMs;
        final safeMax   = maxMs > 0 ? maxMs : 1.0;
        final displayPos = _dragging
            ? Duration(milliseconds: _dragValue.toInt())
            : state.position;
        final remaining  = state.duration - displayPos;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 28.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 3.h,
                      decoration: BoxDecoration(
                        color:        Colors.white24,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (buffMs / safeMax).clamp(0.0, 1.0),
                        child: Container(
                          height: 3.h,
                          decoration: BoxDecoration(
                            color:        Colors.white38,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor:   Colors.white,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor:         Colors.white,
                        overlayColor:       Colors.white24,
                        trackHeight:        3.h,
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 7.r,
                        ),
                      ),
                      child: Slider(
                        value:    sliderVal,
                        min:      0,
                        max:      safeMax,
                        onChanged: (v) => setState(() {
                          _dragging  = true;
                          _dragValue = v;
                        }),
                        onChangeEnd: (v) {
                          setState(() => _dragging = false);
                          widget.bloc.add(
                            VideoSeekEvent(
                                Duration(milliseconds: v.toInt())),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DurationFormatter.format(displayPos),
                      style: TextStyle(
                        color: _dragging ? Colors.white : Colors.white70,
                        fontSize:   11.sp,
                        fontWeight: _dragging
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    Text(
                      '−${DurationFormatter.format(remaining)}',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 11.sp),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Action strip
// ─────────────────────────────────────────────────────────────────────────────

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({
    required this.isMuted,
    required this.volume,
    required this.playbackSpeed,
    required this.fitMode,
    required this.bloc,
    required this.onCycleFit,
  });

  final bool         isMuted;
  final double       volume;
  final double       playbackSpeed;
  final _FitMode     fitMode;
  final VideoBloc    bloc;
  final VoidCallback onCycleFit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 2.h, 8.w, 10.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              color: Colors.white,
              size:  20.r,
            ),
            onPressed: () => bloc.add(const VideoToggleMuteEvent()),
          ),
          _VolumeSlider(bloc: bloc),
          const Spacer(),
          GestureDetector(
            onTap: () => _pickSpeed(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(6.r),
                border:       Border.all(color: Colors.white24, width: .8),
              ),
              child: Text(
                '${playbackSpeed}×',
                style: TextStyle(
                  color:      Colors.white,
                  fontSize:   12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Tooltip(
            message: fitMode.label,
            child: _SmallIconBtn(
              icon:      fitMode.icon,
              // BUG FIX: was calling a local setState that only changed the
              // icon on this widget.  Now calls the parent callback so the
              // video surface's BoxFit actually changes.
              onPressed: onCycleFit,
            ),
          ),
          SizedBox(width: 2.w),
          
        ],
      ),
    );
  }

  void _pickSpeed(BuildContext context) {
    const speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 36.w, height: 4.h,
              decoration: BoxDecoration(
                color:        Colors.white24,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Playback speed',
              style: TextStyle(
                color:      Colors.white,
                fontSize:   15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            ...speeds.map(
              (s) => ListTile(
                title: Text(
                  '${s}×',
                  style: TextStyle(
                    color: s == playbackSpeed
                        ? Colors.white
                        : Colors.white70,
                    fontWeight: s == playbackSpeed
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
                trailing: s == playbackSpeed
                    ? Icon(Icons.check_rounded,
                        color: Colors.white, size: 18.r)
                    : null,
                onTap: () {
                  bloc.add(VideoSetSpeedEvent(s));
                  Navigator.pop(context);
                },
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Volume slider
// ─────────────────────────────────────────────────────────────────────────────

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({required this.bloc});
  final VideoBloc bloc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoBloc, VideoState>(
      buildWhen: (p, n) {
        if (p is VideoReady && n is VideoReady) {
          return p.volume != n.volume || p.isMuted != n.isMuted;
        }
        return false;
      },
      builder: (context, state) {
        if (state is! VideoReady) return const SizedBox.shrink();
        final displayVol = state.isMuted ? 0.0 : state.volume;

        return SizedBox(
          width: 80.w,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor:   Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor:         Colors.white,
              overlayColor:       Colors.white12,
              trackHeight:        2.5.h,
              thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: 5.r),
            ),
            child: Slider(
              value:    displayVol,
              min:      0,
              max:      1,
              onChanged: (v) => bloc.add(VideoSetVolumeEvent(v)),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small icon button
// ─────────────────────────────────────────────────────────────────────────────

class _SmallIconBtn extends StatelessWidget {
  const _SmallIconBtn({required this.icon, required this.onPressed});
  final IconData     icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width:  34.r,
        height: 34.r,
        decoration: BoxDecoration(
          color:        Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: Colors.white70, size: 18.r),
      ),
    );
  }
}