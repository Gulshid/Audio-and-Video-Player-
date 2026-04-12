import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../bloc/audio_bloc.dart';
import '../../bloc/audio_event.dart';
import '../../bloc/audio_state.dart';

/// Professional, enhanced audio controls with animated play button,
/// active-state indicators, and polished icon sizing.
class AudioControls extends StatelessWidget {
  const AudioControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioBloc, AudioState>(
      // FIX: Only rebuild controls when playback-control-relevant state
      // changes. Position/duration ticks (emitted ~4× per second) do NOT
      // affect any control button, so skipping those rebuilds eliminates
      // the jank caused by rebuilding AnimatedSwitcher/AnimatedContainer
      // on every tick.
      buildWhen: (prev, curr) {
        if (prev.runtimeType != curr.runtimeType) return true;
        if (curr is AudioReady && prev is AudioReady) {
          return prev.isPlaying  != curr.isPlaying  ||
                 prev.hasPrev    != curr.hasPrev    ||
                 prev.hasNext    != curr.hasNext    ||
                 prev.repeatMode != curr.repeatMode ||
                 prev.isShuffle  != curr.isShuffle;
        }
        return true;
      },
      builder: (context, state) {
        final s         = state is AudioReady ? state : null;
        final isPlaying = s?.isPlaying ?? false;
        final hasPrev   = s?.hasPrev   ?? false;
        final hasNext   = s?.hasNext   ?? false;
        final repeat    = s?.repeatMode ?? RepeatMode.none;
        final shuffle   = s?.isShuffle  ?? false;
        final enabled   = s != null;

        final bloc    = context.read<AudioBloc>();
        final scheme  = Theme.of(context).colorScheme;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Row 1 : Skip-back / Prev / Play / Next / Skip-fwd ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // Skip backward 10 s
                _SkipButton(
                  icon:    Icons.replay_10_rounded,
                  size:    30.r,
                  enabled: enabled,
                  color:   scheme.onSurface,
                  onTap:   () => bloc.add(const AudioSkipBackwardEvent()),
                ),

                // Previous track
                _TrackNavButton(
                  icon:    Icons.skip_previous_rounded,
                  size:    36.r,
                  active:  hasPrev,
                  color:   scheme.onSurface,
                  onTap:   hasPrev
                      ? () => bloc.add(const AudioPrevTrackEvent())
                      : null,
                ),

                // ── Central Play / Pause ─────────────────────────
                _PlayPauseButton(
                  isPlaying: isPlaying,
                  enabled:   enabled,
                  color:     scheme.primary,
                  onTap:     enabled
                      ? () => bloc.add(
                            isPlaying
                                ? const AudioPauseEvent()
                                : const AudioResumeEvent(),
                          )
                      : null,
                ),

                // Next track
                _TrackNavButton(
                  icon:    Icons.skip_next_rounded,
                  size:    36.r,
                  active:  hasNext,
                  color:   scheme.onSurface,
                  onTap:   hasNext
                      ? () => bloc.add(const AudioNextTrackEvent())
                      : null,
                ),

                // Skip forward 10 s
                _SkipButton(
                  icon:    Icons.forward_10_rounded,
                  size:    30.r,
                  enabled: enabled,
                  color:   scheme.onSurface,
                  onTap:   () => bloc.add(const AudioSkipForwardEvent()),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // ── Row 2 : Shuffle ─────── Repeat ──────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Shuffle
                _ToggleButton(
                  icon:       Icons.shuffle_rounded,
                  activeIcon: Icons.shuffle_rounded,
                  label:      'Shuffle',
                  active:     shuffle,
                  enabled:    enabled,
                  activeColor: scheme.primary,
                  inactiveColor: scheme.onSurface.withOpacity(.35),
                  onTap: () => bloc.add(const AudioToggleShuffleEvent()),
                ),

                // Repeat (cycles none → one → all)
                _RepeatButton(
                  mode:         repeat,
                  enabled:      enabled,
                  activeColor:  scheme.primary,
                  inactiveColor: scheme.onSurface.withOpacity(.35),
                  onTap: () => bloc.add(const AudioToggleRepeatEvent()),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

/// Animated central play/pause button with ripple + shadow.
class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.isPlaying,
    required this.enabled,
    required this.color,
    this.onTap,
  });
  final bool         isPlaying;
  final bool         enabled;
  final Color        color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve:    Curves.easeInOut,
      width:    70.r,
      height:   70.r,
      decoration: BoxDecoration(
        color:  enabled ? color : color.withOpacity(.35),
        shape:  BoxShape.circle,
        boxShadow: enabled
            ? [
                BoxShadow(
                  color:      color.withOpacity(.40),
                  blurRadius: 20,
                  offset:     const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Material(
        color:        Colors.transparent,
        shape:        const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white24,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: child,
            ),
            child: Icon(
              isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              key:   ValueKey(isPlaying),
              color: Colors.white,
              size:  36.r,
            ),
          ),
        ),
      ),
    );
  }
}

/// Previous / Next track buttons with disabled dimming.
class _TrackNavButton extends StatelessWidget {
  const _TrackNavButton({
    required this.icon,
    required this.size,
    required this.active,
    required this.color,
    this.onTap,
  });
  final IconData      icon;
  final double        size;
  final bool          active;
  final Color         color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize:   size,
      icon: AnimatedOpacity(
        opacity:  active ? 1.0 : 0.25,
        duration: const Duration(milliseconds: 200),
        child: Icon(icon, color: color),
      ),
      onPressed: onTap,
      splashRadius: size * 0.75,
      tooltip: icon == Icons.skip_previous_rounded ? 'Previous' : 'Next',
    );
  }
}

/// 10-second skip buttons (always enabled when audio is ready).
class _SkipButton extends StatelessWidget {
  const _SkipButton({
    required this.icon,
    required this.size,
    required this.enabled,
    required this.color,
    required this.onTap,
  });
  final IconData     icon;
  final double       size;
  final bool         enabled;
  final Color        color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize:   size,
      icon: Icon(
        icon,
        color: enabled ? color : color.withOpacity(.25),
      ),
      onPressed: enabled ? onTap : null,
      splashRadius: size * 0.75,
    );
  }
}

/// Shuffle / generic two-state toggle with label and active pip.
class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.enabled,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });
  final IconData icon;
  final IconData activeIcon;
  final String   label;
  final bool     active;
  final bool     enabled;
  final Color    activeColor;
  final Color    inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                active ? activeIcon : icon,
                key:   ValueKey(active),
                size:  22.r,
                color: active ? activeColor : inactiveColor,
              ),
            ),
            SizedBox(height: 4.h),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize:   10.sp,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color:      active ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
            SizedBox(height: 3.h),
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width:    active ? 5.r : 0,
              height:   active ? 5.r : 0,
              decoration: BoxDecoration(
                color:  activeColor,
                shape:  BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Repeat button with three-state cycling (none → one → all).
class _RepeatButton extends StatelessWidget {
  const _RepeatButton({
    required this.mode,
    required this.enabled,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });
  final RepeatMode   mode;
  final bool         enabled;
  final Color        activeColor;
  final Color        inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = mode != RepeatMode.none;
    final icon = mode == RepeatMode.one
        ? Icons.repeat_one_rounded
        : Icons.repeat_rounded;
    final label = switch (mode) {
      RepeatMode.none => 'Repeat',
      RepeatMode.one  => 'Repeat 1',
      RepeatMode.all  => 'Repeat All',
    };

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                icon,
                key:   ValueKey(mode),
                size:  22.r,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            SizedBox(height: 4.h),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize:   10.sp,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color:      isActive ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
            SizedBox(height: 3.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width:    isActive ? 5.r : 0,
              height:   isActive ? 5.r : 0,
              decoration: BoxDecoration(
                color:  activeColor,
                shape:  BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}