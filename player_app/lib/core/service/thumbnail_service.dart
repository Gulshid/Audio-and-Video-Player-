import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailService {
  ThumbnailService._();
  static final ThumbnailService instance = ThumbnailService._();

  int _active = 0;
  static const _maxConcurrent = 3;

  // FIX #3: Queue stores Completers directly. The finally block completes
  // the next one when a slot frees — truly pausing the waiting caller.
  final _queue = <Completer<void>>[];

  Future<String?> getThumbnail(String videoPath,
      {bool isNetwork = false}) async {
    if (isNetwork) return null;

    try {
      final cacheDir  = await getTemporaryDirectory();
      final hash      = videoPath.hashCode.abs();
      final thumbPath = '${cacheDir.path}/thumb_$hash.jpg';

      if (await File(thumbPath).exists()) return thumbPath;

      // FIX #3: Park in the queue and truly wait until a slot is freed.
      if (_active >= _maxConcurrent) {
        final completer = Completer<void>();
        _queue.add(completer);
        await completer.future;
      }

      _active++;
      try {
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
        // Signal the next queued caller that a slot is now free.
        if (_queue.isNotEmpty) {
          _queue.removeAt(0).complete();
        }
      }
    } catch (e, st) {
      debugPrint('⚠️ Thumbnail error for $videoPath\n$e\n$st');
      return null;
    }
  }
}
