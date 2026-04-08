import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailService {
  ThumbnailService._();
  static final ThumbnailService instance = ThumbnailService._();

  // Throttle: only N concurrent generations so the list doesn't
  // flood the platform channel all at once
  int _active = 0;
  static const _maxConcurrent = 3;
  final _queue = <Future<void> Function()>[];

  Future<String?> getThumbnail(String videoPath,
      {bool isNetwork = false}) async {
    if (isNetwork) return null;

    try {
      final cacheDir  = await getTemporaryDirectory();
      final hash      = videoPath.hashCode.abs();
      final thumbPath = '${cacheDir.path}/thumb_$hash.jpg';

      if (await File(thumbPath).exists()) return thumbPath;

      // Queue if too many are running simultaneously
      if (_active >= _maxConcurrent) {
        final completer = Completer<void>();
        _queue.add(() async => completer.complete());
        await completer.future;
      }

      _active++;
      try {
        // ✅ Called on main isolate — platform channels work here
        final result = await VideoThumbnail.thumbnailFile(
          video:         videoPath,
          thumbnailPath: thumbPath,
          imageFormat:   ImageFormat.JPEG,
          timeMs:        1000,
          maxHeight:     120,
          quality:       75,
        );
        debugPrint(result != null
            ? '✅ Thumb OK: $result'
            : '❌ Thumb null: $videoPath');
        return result;
      } finally {
        _active--;
        if (_queue.isNotEmpty) {
          final next = _queue.removeAt(0);
          next();
        }
      }
    } catch (e, st) {
      // Now you'll see the REAL error
      debugPrint('⚠️ Thumbnail error for $videoPath\n$e\n$st');
      return null;
    }
  }
}