import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/scheduler.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

Task _task(Recurrence recurrence) => Task(
  id: 't1',
  ownerId: 'u1',
  title: 'Vacuum the lounge',
  recurrence: recurrence,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  group('Recurrence model', () {
    test('strict recurrence survives a JSON round-trip', () {
      const recurrence = Recurrence.strict(weekdays: [DateTime.monday]);
      final decoded = Recurrence.fromJson(recurrence.toJson());
      expect(decoded, recurrence);
      expect(decoded, isA<StrictRecurrence>());
    });

    test('flexible recurrence survives a JSON round-trip', () {
      const recurrence = Recurrence.flexible(
        timesPerPeriod: 1,
        period: FrequencyPeriod.week,
        windowDays: 3,
      );
      final decoded = Recurrence.fromJson(recurrence.toJson());
      expect(decoded, recurrence);
      expect(decoded, isA<FlexibleRecurrence>());
    });
  });

  group('PlaceholderScheduler (until the real engine lands)', () {
    const scheduler = PlaceholderScheduler();

    test('buildToday returns an empty checklist for now', () {
      final today = scheduler.buildToday(
        tasks: [
          _task(const Recurrence.strict(weekdays: [DateTime.monday])),
        ],
        today: DateTime(2026, 6, 29), // a Monday
      );
      expect(today, isEmpty);
    });

    test('rescheduleMissed is not implemented yet', () {
      final missed = TaskOccurrence(
        id: 'o1',
        taskId: 't1',
        scheduledDate: DateTime(2026, 6, 29),
      );
      expect(
        () => scheduler.rescheduleMissed(
          task: _task(const Recurrence.flexible()),
          missed: missed,
          now: DateTime(2026, 6, 30),
        ),
        throwsUnimplementedError,
      );
    });
  });

  group('Scheduler behaviour — TODO(upcoming): real engine', () {
    test(
      'strict "every Monday" produces an occurrence on Mondays only',
      () {},
      skip: 'Implement when the real Scheduler replaces PlaceholderScheduler.',
    );

    test(
      'flexible "once a week" slides within its window when missed, '
      'rather than piling up',
      () {},
      skip: 'Implement when the real Scheduler replaces PlaceholderScheduler.',
    );
  });
}
