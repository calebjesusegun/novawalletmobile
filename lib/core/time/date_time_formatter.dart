/// Centralized date and time formatting utilities for NovaWallet.
///
/// Ensures all timestamps are converted to local time (WAT, UTC+1 in Nigeria)
/// without double-offsetting (no artificial WAT+1).
class DateTimeFormatter {
  const DateTimeFormatter._();

  static const List<String> shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> fullMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Formats a date as `30 Dec 2026` (or `d MMM yyyy`).
  static String formatDate(DateTime dt) {
    final local = dt.toLocal();
    final month = shortMonths[local.month - 1];
    return '${local.day} $month ${local.year}';
  }

  /// Formats month and year as `December 2026`.
  static String formatMonthYear(DateTime dt) {
    final local = dt.toLocal();
    final month = fullMonths[local.month - 1];
    return '$month ${local.year}';
  }

  /// Formats timestamp as `Sep 22, 2026 at 5:50 AM`.
  static String formatFullTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final month = fullMonths[local.month - 1];
    final hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    return '$month ${local.day}, ${local.year} at $hour:$minute $amPm';
  }

  /// Formats short timestamp as `Sep 22, 5:50 AM`.
  static String formatShortTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final month = shortMonths[local.month - 1];
    final hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    return '$month ${local.day}, $hour:$minute $amPm';
  }

  /// Formats receipt timestamp as `22 Sep 2026, 05:50`.
  static String formatReceiptTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = shortMonths[local.month - 1];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day $month ${local.year}, $hour:$minute';
  }

  /// Checks if [date] is strictly in the future compared to the beginning of today.
  static bool isFutureDate(DateTime date, {DateTime? relativeTo}) {
    final ref = (relativeTo ?? DateTime.now()).toLocal();
    final startOfToday = DateTime(ref.year, ref.month, ref.day);
    final localDate = date.toLocal();
    final targetDay = DateTime(localDate.year, localDate.month, localDate.day);
    return targetDay.isAfter(startOfToday);
  }
}
