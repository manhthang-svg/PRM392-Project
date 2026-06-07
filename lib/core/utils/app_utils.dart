import 'package:intl/intl.dart';

/// Các helper functions dùng chung trong toàn ứng dụng
class AppUtils {
  AppUtils._();

  /// Format ngày tháng theo định dạng dd/MM/yyyy
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format ngày tháng theo định dạng dd MMM yyyy
  static String formatDateFull(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format thời gian theo định dạng HH:mm
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Format ngày tháng năm và giờ
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Tính thời gian tương đối (vd: "2 hours ago")
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return formatDate(date);
    }
  }

  /// Validate email address
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password (ít nhất 8 ký tự)
  static bool isValidPassword(String password) {
    return password.length >= 8;
  }

  /// Truncate text nếu quá dài
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
