import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _displayFormat = DateFormat('MMM dd, yyyy');

  static String format(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final date = DateTime.parse(isoDate);
      return _displayFormat.format(date);
    } catch (_) {
      return '';
    }
  }

  static String timeAgo(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return _displayFormat.format(date);
    } catch (_) {
      return '';
    }
  }
}
