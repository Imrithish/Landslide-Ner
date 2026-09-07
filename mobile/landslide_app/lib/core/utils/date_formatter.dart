import 'package:intl/intl.dart';

/// Utilities for formatting dates and timestamps across the application
class DateFormatter {
  static String formatDateTime(dynamic date) {
    if (date == null) return 'N/A';
    DateTime dt;
    if (date is DateTime) {
      dt = date;
    } else if (date is String) {
      dt = DateTime.tryParse(date) ?? DateTime.now();
    } else {
      return 'N/A';
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }

  static String formatDate(dynamic date) {
    if (date == null) return 'N/A';
    DateTime dt;
    if (date is DateTime) {
      dt = date;
    } else if (date is String) {
      dt = DateTime.tryParse(date) ?? DateTime.now();
    } else {
      return 'N/A';
    }
    return DateFormat('dd MMM yyyy').format(dt.toLocal());
  }

  static String formatRelative(dynamic date) {
    if (date == null) return 'N/A';
    DateTime dt;
    if (date is DateTime) {
      dt = date;
    } else if (date is String) {
      dt = DateTime.tryParse(date) ?? DateTime.now();
    } else {
      return 'N/A';
    }

    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dt.toLocal());
  }
}
