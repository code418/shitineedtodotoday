// Shared calendar labels so weekday/month names and simple date formatting
// live in one place instead of being copy-pasted across screens and the
// scheduling domain. Pure Dart (no Flutter) so domain code can use it too.

/// Full weekday names, indexed by `DateTime.weekday - 1` (Monday … Sunday).
const List<String> kWeekdayNamesLong = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Three-letter weekday names, indexed by `DateTime.weekday - 1`.
const List<String> kWeekdayNamesShort = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// Three-letter month names, indexed by `DateTime.month - 1`.
const List<String> kMonthNamesShort = [
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

/// Full weekday name for [date] (e.g. "Monday").
String weekdayLong(DateTime date) => kWeekdayNamesLong[date.weekday - 1];

/// Three-letter weekday name for [date] (e.g. "Mon").
String weekdayShort(DateTime date) => kWeekdayNamesShort[date.weekday - 1];

/// Three-letter month name for [date] (e.g. "Jul").
String monthShort(DateTime date) => kMonthNamesShort[date.month - 1];

/// e.g. "5 Jul 2026".
String dayMonthYear(DateTime date) =>
    '${date.day} ${monthShort(date)} ${date.year}';
