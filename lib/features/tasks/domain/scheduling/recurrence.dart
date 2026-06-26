import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurrence.freezed.dart';
part 'recurrence.g.dart';

/// The period a [FlexibleRecurrence] frequency is counted over.
enum FrequencyPeriod { day, week, month, year }

/// A coarse seasonal anchor for very fuzzy schedules (e.g. "every summer").
///
/// Hemisphere handling is deliberately left to the scheduler implementation.
enum Season { spring, summer, autumn, winter }

/// How often a task needs doing.
///
/// This is the heart of the app: it spans the full range from **strict** timing
/// (every Monday, the 1st of the month, a one-off date) to **fuzzy** timing
/// (once a week, twice a month, once every summer) where the exact day can
/// float and is chosen — or neatly rescheduled — by the [Scheduler].
@freezed
sealed class Recurrence with _$Recurrence {
  const Recurrence._();

  /// Strict timing that materialises on exact, predictable days.
  ///
  /// - [weekdays]: ISO weekday numbers (1 = Mon … 7 = Sun), e.g. `[1]` for
  ///   "every Monday" or `[1, 4]` for "Mondays and Thursdays".
  /// - [dayOfMonth]: 1–31 for "the Nth of every month".
  /// - [exactDate]: a single, one-off date.
  ///
  /// Exactly one dimension is expected to be set; validation is the
  /// scheduler's job.
  const factory Recurrence.strict({
    @Default(<int>[]) List<int> weekdays,
    int? dayOfMonth,
    DateTime? exactDate,
  }) = StrictRecurrence;

  /// Fuzzy timing: do this [timesPerPeriod] times per [period], with a
  /// [windowDays] tolerance so the scheduler can pick — and slide — the actual
  /// day to keep daily load manageable.
  ///
  /// [season] optionally anchors very coarse schedules such as "every summer".
  const factory Recurrence.flexible({
    @Default(1) int timesPerPeriod,
    @Default(FrequencyPeriod.week) FrequencyPeriod period,
    @Default(0) int windowDays,
    Season? season,
  }) = FlexibleRecurrence;

  factory Recurrence.fromJson(Map<String, dynamic> json) =>
      _$RecurrenceFromJson(json);
}
