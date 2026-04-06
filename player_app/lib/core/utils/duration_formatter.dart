/// Formats a [Duration] to a human-readable string.
/// Examples:
///   3:05   → 3 minutes 5 seconds
///   1:02:30 → 1 hour 2 minutes 30 seconds
abstract final class DurationFormatter {
  static String format(Duration duration) {
    final h  = duration.inHours;
    final m  = duration.inMinutes.remainder(60);
    final s  = duration.inSeconds.remainder(60);

    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');

    if (h > 0) {
      return '$h:$mm:$ss';
    }
    return '$m:$ss';
  }
}
