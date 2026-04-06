import 'package:equatable/equatable.dart';

enum MediaType { audio, video }

class MediaItem extends Equatable {
  const MediaItem({
    required this.id,
    required this.title,
    required this.path,
    required this.type,
    this.artist,
    this.albumArt,
    this.duration,
    this.isFavorite = false,
    this.lastPositionSeconds = 0,
  });

  final String    id;
  final String    title;
  final String    path;            // local file path OR network URL
  final MediaType type;
  final String?   artist;
  final String?   albumArt;        // local path or URL to thumbnail/cover art
  final Duration? duration;
  final bool      isFavorite;
  final int       lastPositionSeconds;

  bool get isNetwork =>
      path.startsWith('http://') || path.startsWith('https://');

  Duration get lastPosition => Duration(seconds: lastPositionSeconds);

  MediaItem copyWith({
    String?    id,
    String?    title,
    String?    path,
    MediaType? type,
    String?    artist,
    String?    albumArt,
    Duration?  duration,
    bool?      isFavorite,
    int?       lastPositionSeconds,
  }) =>
      MediaItem(
        id:                  id                  ?? this.id,
        title:               title               ?? this.title,
        path:                path                ?? this.path,
        type:                type                ?? this.type,
        artist:              artist              ?? this.artist,
        albumArt:            albumArt            ?? this.albumArt,
        duration:            duration            ?? this.duration,
        isFavorite:          isFavorite          ?? this.isFavorite,
        lastPositionSeconds: lastPositionSeconds ?? this.lastPositionSeconds,
      );

  // ── Hive / JSON helpers ────────────────────────────────
  Map<String, dynamic> toMap() => {
        'id':                  id,
        'title':               title,
        'path':                path,
        'type':                type.index,
        'artist':              artist,
        'albumArt':            albumArt,
        'durationMs':          duration?.inMilliseconds,
        'isFavorite':          isFavorite,
        'lastPositionSeconds': lastPositionSeconds,
      };

  factory MediaItem.fromMap(Map<dynamic, dynamic> map) => MediaItem(
        id:                  map['id'] as String,
        title:               map['title'] as String,
        path:                map['path'] as String,
        type:                MediaType.values[map['type'] as int],
        artist:              map['artist'] as String?,
        albumArt:            map['albumArt'] as String?,
        duration:            map['durationMs'] != null
            ? Duration(milliseconds: map['durationMs'] as int)
            : null,
        isFavorite:          map['isFavorite'] as bool? ?? false,
        lastPositionSeconds: map['lastPositionSeconds'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [
        id, title, path, type, artist, albumArt,
        duration, isFavorite, lastPositionSeconds,
      ];
}
