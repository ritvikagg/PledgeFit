/// Local date-only utilities (no timezone conversion surprises).
class MvpDateUtils {
  /// Removes the time component in the local timezone.
  static DateTime dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  static bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime addDays(DateTime dateOnly, int days) {
    return dateOnly.add(Duration(days: days));
  }

  /// Inclusive day number: if `startDate` is today, returns 1.
  static int dayNumber(DateTime startDate, DateTime nowDate) {
    final start = dateOnly(startDate);
    final now = dateOnly(nowDate);
    return now.difference(start).inDays + 1;
  }

  static int daysBetween(DateTime startDate, DateTime endDate) {
    final start = dateOnly(startDate);
    final end = dateOnly(endDate);
    return end.difference(start).inDays;
  }
}

