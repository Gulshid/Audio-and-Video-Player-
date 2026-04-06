import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/widgets/responsive_builder.dart';
import '../../bloc/video_bloc.dart';
import '../../bloc/video_event.dart';
import '../../bloc/video_state.dart';
import '../../../../features/playlist/domain/entities/media_item.dart';
import '../widgets/video_controls.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({required this.item, super.key});
  final MediaItem item;

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  @override
  void initState() {
    super.initState();
    context.read<VideoBloc>().add(VideoInitializeEvent(widget.item));
    // Force landscape for a cinema feel on phones
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    context.read<VideoBloc>().add(const VideoDisposeEvent());
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<VideoBloc, VideoState>(
        builder: (context, state) {
          if (state is VideoLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (state is VideoError) {
            return _ErrorView(message: state.message);
          }

          if (state is VideoReady) {
            return ResponsiveBuilder(
              builder: (context, device) {
                return Stack(
                  children: [
                    // ── Video surface ──────────────────────
                    Center(
                      child: AspectRatio(
                        aspectRatio: state.controller.value.aspectRatio,
                        child: VideoPlayer(state.controller),
                      ),
                    ),

                    // ── Controls overlay ───────────────────
                    const Positioned.fill(child: VideoControls()),
                  ],
                );
              },
            );
          }

          // VideoInitial
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 64.r),
            SizedBox(height: 16.h),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
