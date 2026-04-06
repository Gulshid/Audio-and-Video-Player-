abstract final class AppConstants {
  // Hive box names
  static const playlistBox  = 'playlist_box';
  static const favoritesBox = 'favorites_box';
  static const settingsBox  = 'settings_box';

  // SharedPreferences keys
  static const lastPlayedKey   = 'last_played_id';
  static const lastPositionKey = 'last_position_seconds';

  // Supported audio extensions
  static const audioExtensions = ['mp3', 'aac', 'wav', 'm4a', 'flac', 'ogg'];

  // Supported video extensions
  static const videoExtensions = ['mp4', 'mkv', 'mov', 'avi', 'webm', 'm4v'];

  // Seek durations
  static const seekForward  = Duration(seconds: 10);
  static const seekBackward = Duration(seconds: 10);

  // Mini-player height (used in Scaffold body padding)
  static const miniPlayerHeight = 72.0;
}
