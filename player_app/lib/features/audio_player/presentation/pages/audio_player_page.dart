import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;

import '../../../../core/widgets/responsive_builder.dart';
import '../../../playlist/domain/entities/media_item.dart';
import '../../bloc/audio_bloc.dart';
import '../../bloc/audio_event.dart';
import '../../bloc/audio_state.dart';
import '../widgets/audio_controls.dart';
import '../widgets/audio_progress_bar.dart';

// FIX — ROOT CAUSE OF FREEZE / BLANK SCREEN:
// The page was opened while AudioBloc was still in AudioLoading state.
// AudioLoading has no currentItem, so the page had nothing to display
// until AudioReady arrived (which could take 1-3 s on Android SAF
// content:// URIs). The fix: accept the MediaItem as an initialItem
// argument so the page can render title / artist / album art immediately,
// with a small spinner on the album art while audio finishes loading.

class AudioPlayerPage extends StatelessWidget {
  /// Passed from the navigation call site so the page can display track
  /// info immediately — before AudioBloc reaches AudioReady.
  final MediaItem? initialItem;

  const AudioPlayerPage({super.key, this.initialItem});

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
              ? _PhoneLayout(initialItem: initialItem)
              : _TabletLayout(initialItem: initialItem);
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

// ── Phone layout ──────────────────────────────────────────────

class _PhoneLayout extends StatelessWidget {
  final MediaItem? initialItem;
  const _PhoneLayout({this.initialItem});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioBloc, AudioState>(
      builder: (context, state) {

        if (state is AudioError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 48.r,
                      color: Theme.of(context).colorScheme.error),
                  SizedBox(height: 12.h),
                  Text(state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          );
        }

        final s         = state is AudioReady ? state : null;
        final isLoading = state is AudioLoading || state is AudioInitial;

        // KEY FIX: use AudioReady data when available, else fall back to
        // initialItem passed from the navigation call site. This means the
        // page shows real track info the moment it opens — no blank/dash UI.
        final displayItem = s?.currentItem ?? initialItem;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(
              children: [
                SizedBox(height: 24.h),

                // ── Album art + subtle loading ring ────────
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _AlbumArt(albumArt: displayItem?.albumArt),
                    if (isLoading)
                      SizedBox(
                        width:  52.r,
                        height: 52.r,
                        child: CircularProgressIndicator(
                          color:       Colors.white70,
                          strokeWidth: 3,
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 32.h),

                // ── Title & artist — shown immediately ─────
                _TrackInfo(
                  title:  displayItem?.title  ?? '—',
                  artist: displayItem?.artist ?? '',
                ),

                SizedBox(height: 24.h),
                const AudioProgressBar(),
                SizedBox(height: 16.h),
                const AudioControls(),
                SizedBox(height: 24.h),
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

// ── Tablet layout ─────────────────────────────────────────────

class _TabletLayout extends StatelessWidget {
  final MediaItem? initialItem;
  const _TabletLayout({this.initialItem});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioBloc, AudioState>(
      builder: (context, state) {
        if (state is AudioError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Text(state.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          );
        }

        final s           = state is AudioReady ? state : null;
        final isLoading   = state is AudioLoading || state is AudioInitial;
        final displayItem = s?.currentItem ?? initialItem;

        return SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(40.r),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _AlbumArt(albumArt: displayItem?.albumArt),
                      if (isLoading)
                        SizedBox(
                          width:  52.r,
                          height: 52.r,
                          child: CircularProgressIndicator(
                            color: Colors.white70, strokeWidth: 3,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 40.h, 40.w, 40.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TrackInfo(
                        title:  displayItem?.title  ?? '—',
                        artist: displayItem?.artist ?? '',
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
                    : FileImage(File(albumArt!)),
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
        Text(title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 6.h),
        Text(artist,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium),
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
            value: volume, min: 0, max: 1,
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
