import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String greetingTime() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String formatDate(DateTime dt) =>
      DateFormat('EEEE, d MMMM').format(dt);

  static String formatShortDate(DateTime dt) =>
      DateFormat('d MMM yyyy').format(dt);

  static String formatTime(String time) {
    // time is "HH:mm" string
    try {
      final parts = time.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final dt = DateTime(2000, 1, 1, h, m);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return time;
    }
  }

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return formatShortDate(dt);
  }

  static String waitTime(DateTime since) {
    final diff = DateTime.now().difference(since);
    if (diff.inSeconds < 60) return '< 1 min';
    if (diff.inMinutes == 1) return '1 min';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  static bool isToday(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    } catch (_) {
      return false;
    }
  }

  static String todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());
}
