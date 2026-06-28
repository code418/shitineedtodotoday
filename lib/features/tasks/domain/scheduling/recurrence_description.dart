import '../../../../core/util/date_labels.dart';
import 'recurrence.dart';

String _ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

/// Returns a friendly British-English description of [r].
///
/// These are data descriptions, not app chrome — they are NOT routed through
/// [AppStrings].
String describeRecurrence(Recurrence r) {
  switch (r) {
    case StrictRecurrence(:final exactDate, :final dayOfMonth, :final weekdays):
      if (exactDate != null) {
        return 'One-off on ${dayMonthYear(exactDate)}';
      }
      if (dayOfMonth != null) {
        return 'The ${_ordinal(dayOfMonth)} of each month';
      }
      if (weekdays.isEmpty) return 'No set schedule';
      // All 7 weekdays?
      final sorted = List<int>.from(weekdays)..sort();
      if (sorted.length == 7) return 'Every day';
      final names = sorted.map((w) => kWeekdayNamesLong[w - 1]).toList();
      if (names.length == 1) return 'Every ${names.first}';
      final last = names.last;
      final rest = names.sublist(0, names.length - 1);
      return 'Every ${rest.join(', ')} and $last';

    case FlexibleRecurrence(
      :final season,
      :final timesPerPeriod,
      :final period,
    ):
      if (season != null) return 'Every ${season.name}';
      final n = timesPerPeriod;
      return switch (period) {
        FrequencyPeriod.day => n == 1 ? 'Every day' : '$n times a day',
        FrequencyPeriod.week => n == 1 ? 'Once a week' : '$n times a week',
        FrequencyPeriod.month => n == 1 ? 'Once a month' : '$n times a month',
        FrequencyPeriod.year => n == 1 ? 'Once a year' : '$n times a year',
      };
  }
}
