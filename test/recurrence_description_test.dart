import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence_description.dart';

void main() {
  group('describeRecurrence', () {
    test('every Monday', () {
      expect(
        describeRecurrence(
          const Recurrence.strict(weekdays: [DateTime.monday]),
        ),
        'Every Monday',
      );
    });

    test('Mon + Thu → "Every Monday and Thursday"', () {
      expect(
        describeRecurrence(
          const Recurrence.strict(
            weekdays: [DateTime.monday, DateTime.thursday],
          ),
        ),
        'Every Monday and Thursday',
      );
    });

    test('all 7 weekdays → "Every day"', () {
      expect(
        describeRecurrence(
          const Recurrence.strict(weekdays: [1, 2, 3, 4, 5, 6, 7]),
        ),
        'Every day',
      );
    });

    test('dayOfMonth 21 → "The 21st of each month"', () {
      expect(
        describeRecurrence(const Recurrence.strict(dayOfMonth: 21)),
        'The 21st of each month',
      );
    });

    test('dayOfMonth 2 → "The 2nd of each month"', () {
      expect(
        describeRecurrence(const Recurrence.strict(dayOfMonth: 2)),
        'The 2nd of each month',
      );
    });

    test('dayOfMonth 3 → "The 3rd of each month"', () {
      expect(
        describeRecurrence(const Recurrence.strict(dayOfMonth: 3)),
        'The 3rd of each month',
      );
    });

    test('dayOfMonth 11 → "The 11th of each month" (teens exception)', () {
      expect(
        describeRecurrence(const Recurrence.strict(dayOfMonth: 11)),
        'The 11th of each month',
      );
    });

    test('exactDate → "One-off on 25 Dec 2026"', () {
      expect(
        describeRecurrence(
          Recurrence.strict(exactDate: DateTime(2026, 12, 25)),
        ),
        'One-off on 25 Dec 2026',
      );
    });

    test('flexible week (1) → "Once a week"', () {
      expect(
        describeRecurrence(
          const Recurrence.flexible(period: FrequencyPeriod.week),
        ),
        'Once a week',
      );
    });

    test('flexible month (2) → "2 times a month"', () {
      expect(
        describeRecurrence(
          const Recurrence.flexible(
            timesPerPeriod: 2,
            period: FrequencyPeriod.month,
          ),
        ),
        '2 times a month',
      );
    });

    test('season summer → "Every summer"', () {
      expect(
        describeRecurrence(const Recurrence.flexible(season: Season.summer)),
        'Every summer',
      );
    });

    test('empty weekdays → "No set schedule"', () {
      expect(describeRecurrence(const Recurrence.strict()), 'No set schedule');
    });
  });
}
