import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;

import '../../../../core/widgets/responsive_builder.dart';
import '../../bloc/audio_bloc.dart';
import '../../bloc/audio_event.dart';
import '../../bloc/audio_state.dart';
import '../widgets/audio_controls.dart';
import '../widgets/audio_progress_bar.dart';

class AudioPlayerPage extends StatelessWidget {
  const AudioPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          iconSize: 32.r,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      body: ResponsiveBuilder(
        builder: (context, device) {
          return device == DeviceType.phone
              ? const _PhoneLayout()
              : const _TabletLayout();
        },
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final bloc = context.read<AudioBloc>();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _OptionsSheet(bloc: bloc),
    );
  }
}

// ── Phone layout : vertical stack ────────────────────────────

class _PhoneLayout extends StatelessWidget {
  const _PhoneLayout();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioBloc, AudioState>(
      builder: (context, state) {
        final s = state is AudioReady ? state : null;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(
              children: [
                SizedBox(height: 24.h),

                // ── Album art ──────────────────────────────
                _AlbumArt(albumArt: s?.currentItem.albumArt),

                SizedBox(height: 32.h),

                // ── Title & artist ─────────────────────────
                _TrackInfo(
                  title:  s?.currentItem.title  ?? '—',
                  artist: s?.currentItem.artist ?? '',
                ),

                SizedBox(height: 24.h),

                // ── Progress bar ───────────────────────────
                const AudioProgressBar(),

                SizedBox(height: 16.h),

                // ── Controls ───────────────────────────────
                const AudioControls(),

                SizedBox(height: 24.h),

                // ── Volume slider ──────────────────────────
                _VolumeRow(volume: s?.volume ?? 1.0),

                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Tablet layout : side-by-side ─────────────────────────────

class _TabletLayout extends StatelessWidget {
  const _TabletLayout();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioBloc, AudioState>(
      builder: (context, state) {
        final s = state is AudioReady ? state : null;

        return SafeArea(
          child: Row(
            children: [
              // Left — album art
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(40.r),
                  child: _AlbumArt(albumArt: s?.currentItem.albumArt),
                ),
              ),

              // Right — info + controls
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 40.h, 40.w, 40.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TrackInfo(
                        title:  s?.currentItem.title  ?? '—',
                        artist: s?.currentItem.artist ?? '',
                      ),
                      SizedBox(height: 32.h),
                      const AudioProgressBar(),
                      SizedBox(height: 24.h),
                      const AudioControls(),
                      SizedBox(height: 24.h),
                      _VolumeRow(volume: s?.volume ?? 1.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────

class _AlbumArt extends StatelessWidget {
  const _AlbumArt({this.albumArt});
  final String? albumArt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size   = 240.r;

    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        color:        scheme.primary.withOpacity(.12),
        boxShadow: [
          BoxShadow(
            color:      scheme.primary.withOpacity(.25),
            blurRadius: 30,
            offset:     const Offset(0, 10),
          ),
        ],
        image: albumArt != null
            ? DecorationImage(
                image: albumArt!.startsWith('http')
                    ? NetworkImage(albumArt!) as ImageProvider
                    : AssetImage(albumArt!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: albumArt == null
          ? Icon(Icons.music_note_rounded, size: 80.r, color: scheme.primary)
          : null,
    );
  }
}

class _TrackInfo extends StatelessWidget {
  const _TrackInfo({required this.title, required this.artist});
  final String title;
  final String artist;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 6.h),
        Text(
          artist,
          maxLines: 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({required this.volume});
  final double volume;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AudioBloc>();
    return Row(
      children: [
        Icon(Icons.volume_down_rounded, size: 20.r,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.5)),
        Expanded(
          child: Slider(
            value: volume,
            min:   0,
            max:   1,
            onChanged: (v) => bloc.add(AudioSetVolumeEvent(v)),
          ),
        ),
        Icon(Icons.volume_up_rounded, size: 20.r,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.5)),
      ],
    );
  }
}

class _OptionsSheet extends StatelessWidget {
  const _OptionsSheet({required this.bloc});
  final AudioBloc bloc;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.stop_rounded),
            title: const Text('Stop playback'),
            onTap: () {
              bloc.add(const AudioStopEvent());
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
