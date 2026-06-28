import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/tasks/domain/scheduling/forgiving_scheduler.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

Task _task(Recurrence recurrence, {String id = 't1', bool isActive = true}) =>
    Task(
      id: id,
      ownerId: 'u1',
      title: 'Vacuum the lounge',
      recurrence: recurrence,
      isActive: isActive,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  const scheduler = ForgivingScheduler();

  // 2026-06-29 is a Monday; 2026-06-30 a Tuesday; 2026-07-01 a Wednesday.
  final monday = DateTime(2026, 6, 29);
  final tuesday = DateTime(2026, 6, 30);
  final wednesday = DateTime(2026, 7, 1);

  group('occurrenceId', () {
    test('is deterministic and zero-padded', () {
      expect(occurrenceId('t1', DateTime(2026, 6, 29)), 't1_2026-06-29');
      expect(
        occurrenceId('t1', DateTime(2026, 6, 29, 23, 59)),
        't1_2026-06-29',
        reason: 'time of day is ignored',
      );
    });
  });

  group('buildToday — strict', () {
    test('"every Monday" produces an occurrence on Mondays only', () {
      final task = _task(const Recurrence.strict(weekdays: [DateTime.monday]));

      final onMonday = scheduler.buildToday(tasks: [task], today: monday);
      expect(onMonday, hasLength(1));
      expect(onMonday.single.taskId, 't1');
      expect(onMonday.single.scheduledDate, monday);
      expect(onMonday.single.status, OccurrenceStatus.pending);

      final onTuesday = scheduler.buildToday(tasks: [task], today: tuesday);
      expect(onTuesday, isEmpty);
    });

    test('day-of-month clamps to the last day for short months', () {
      final task = _task(const Recurrence.strict(dayOfMonth: 31));
      // February 2026 has 28 days, so the 31st clamps to the 28th.
      expect(
        scheduler.buildToday(tasks: [task], today: DateTime(2026, 2, 28)),
        hasLength(1),
      );
      expect(
        scheduler.buildToday(tasks: [task], today: DateTime(2026, 2, 27)),
        isEmpty,
      );
      // A 31-day month still lands on the 31st.
      expect(
        scheduler.buildToday(tasks: [task], today: DateTime(2026, 7, 31)),
        hasLength(1),
      );
    });

    test('exactDate produces a single one-off occurrence', () {
      final task = _task(Recurrence.strict(exactDate: DateTime(2026, 12, 25)));
      expect(
        scheduler.buildToday(tasks: [task], today: DateTime(2026, 12, 25)),
        hasLength(1),
      );
      expect(
        scheduler.buildToday(tasks: [task], today: DateTime(2026, 12, 24)),
        isEmpty,
      );
    });
  });

  group('buildToday — flexible', () {
    test('"once a week" anchors to the Monday of the week', () {
      final task = _task(
        const Recurrence.flexible(period: FrequencyPeriod.week),
      );
      final occ = scheduler.buildToday(tasks: [task], today: monday);
      expect(occ, hasLength(1));
      expect(occ.single.scheduledDate, monday);
      expect(occ.single.windowStart, monday);
      expect(
        occ.single.windowEnd,
        DateTime(2026, 7, 5),
      ); // the following Sunday
      // Not anchored to a non-start weekday.
      expect(scheduler.buildToday(tasks: [task], today: tuesday), isEmpty);
    });

    test('"twice a week" spreads to two anchor days', () {
      final task = _task(
        const Recurrence.flexible(
          timesPerPeriod: 2,
          period: FrequencyPeriod.week,
        ),
      );
      // Anchors at offsets floor(0*7/2)=0 (Mon) and floor(1*7/2)=3 (Thu).
      expect(scheduler.buildToday(tasks: [task], today: monday), hasLength(1));
      expect(
        scheduler.buildToday(tasks: [task], today: DateTime(2026, 7, 2)),
        hasLength(1),
        reason: 'Thursday is the second anchor',
      );
      expect(
        scheduler.buildToday(tasks: [task], today: DateTime(2026, 7, 1)),
        isEmpty,
        reason: 'Wednesday is between anchors',
      );
    });

    test('daily flexible occurs every day', () {
      final task = _task(
        const Recurrence.flexible(period: FrequencyPeriod.day),
      );
      expect(scheduler.buildToday(tasks: [task], today: monday), hasLength(1));
      expect(scheduler.buildToday(tasks: [task], today: tuesday), hasLength(1));
    });

    test('windowDays caps the slide window inside the period', () {
      final task = _task(
        const Recurrence.flexible(period: FrequencyPeriod.week, windowDays: 2),
      );
      final occ = scheduler.buildToday(tasks: [task], today: monday).single;
      expect(occ.windowEnd, DateTime(2026, 7, 1)); // Monday + 2 days
    });

    test('seasonal "every summer" anchors to 1 June', () {
      final task = _task(const Recurrence.flexible(season: Season.summer));
      expect(
        scheduler.buildToday(tasks: [task], today: DateTime(2026, 6)),
        hasLength(1),
      );
      expect(
        scheduler.buildToday(tasks: [task], today: DateTime(2026, 7)),
        isEmpty,
      );
    });
  });

  group('buildToday — dedupe & filtering', () {
    test('keeps an existing occurrence for today and does not duplicate', () {
      final task = _task(const Recurrence.strict(weekdays: [DateTime.monday]));
      final existing = TaskOccurrence(
        id: occurrenceId('t1', monday),
        taskId: 't1',
        scheduledDate: monday,
        status: OccurrenceStatus.done,
        completedAt: monday,
        actualDurationMinutes: 12,
      );
      final list = scheduler.buildToday(
        tasks: [task],
        today: monday,
        existing: [existing],
      );
      expect(list, hasLength(1));
      expect(list.single.status, OccurrenceStatus.done);
      expect(list.single.actualDurationMinutes, 12);
    });

    test('includes an occurrence rescheduled into today', () {
      final task = _task(const Recurrence.flexible());
      final moved = TaskOccurrence(
        id: 'o-moved',
        taskId: 't1',
        scheduledDate: monday,
        status: OccurrenceStatus.rescheduled,
        originalDate: DateTime(2026, 6, 25),
      );
      final list = scheduler.buildToday(
        tasks: [task],
        today: monday,
        existing: [moved],
      );
      expect(list.map((o) => o.id), contains('o-moved'));
    });

    test('skips inactive tasks', () {
      final task = _task(
        const Recurrence.strict(weekdays: [DateTime.monday]),
        isActive: false,
      );
      expect(scheduler.buildToday(tasks: [task], today: monday), isEmpty);
    });

    test(
      'an occurrence moved to another day is not regenerated on its original day',
      () {
        // Regression: a strict-Monday task whose occurrence was moved to
        // Wednesday (same deterministic id, different scheduledDate) must NOT be
        // regenerated on Monday, but must still appear on Wednesday.
        final task = _task(
          const Recurrence.strict(weekdays: [DateTime.monday]),
        );
        final moved = TaskOccurrence(
          id: occurrenceId('t1', monday),
          taskId: 't1',
          scheduledDate: wednesday,
          status: OccurrenceStatus.rescheduled,
          originalDate: monday,
        );

        // Monday: the id already exists → no regeneration.
        final onMonday = scheduler.buildToday(
          tasks: [task],
          today: monday,
          existing: [moved],
        );
        expect(
          onMonday,
          isEmpty,
          reason:
              'moved occurrence must not be regenerated on its original day',
        );

        // Wednesday: the occurrence is scheduled there → it appears.
        final onWednesday = scheduler.buildToday(
          tasks: [task],
          today: wednesday,
          existing: [moved],
        );
        expect(onWednesday, hasLength(1));
        expect(onWednesday.single.id, occurrenceId('t1', monday));
        expect(onWednesday.single.scheduledDate, wednesday);
      },
    );

    test('a skipped occurrence is hidden from today and not regenerated', () {
      final task = _task(const Recurrence.strict(weekdays: [DateTime.monday]));
      final skipped = TaskOccurrence(
        id: occurrenceId('t1', monday),
        taskId: 't1',
        scheduledDate: monday,
        status: OccurrenceStatus.skipped,
      );
      final list = scheduler.buildToday(
        tasks: [task],
        today: monday,
        existing: [skipped],
      );
      expect(
        list,
        isEmpty,
        reason: 'skipped occurrence is hidden AND not regenerated',
      );
    });
  });

  group('rescheduleMissed — flexible', () {
    test('slides forward a day within the window, forgiving the slip', () {
      final task = _task(
        const Recurrence.flexible(period: FrequencyPeriod.week),
      );
      final missed = TaskOccurrence(
        id: occurrenceId('t1', monday),
        taskId: 't1',
        scheduledDate: monday,
        originalDate: monday,
        windowStart: monday,
        windowEnd: DateTime(2026, 7, 5),
      );
      final moved = scheduler.rescheduleMissed(
        task: task,
        missed: missed,
        now: tuesday,
      );
      expect(moved.status, OccurrenceStatus.rescheduled);
      expect(moved.scheduledDate, tuesday); // slid one day, onto today (Tue)
      expect(moved.originalDate, monday, reason: 'original date is preserved');
    });

    test('clamps at the window end rather than stacking past it', () {
      final task = _task(
        const Recurrence.flexible(period: FrequencyPeriod.week),
      );
      final windowEnd = DateTime(2026, 7, 5);
      final missed = TaskOccurrence(
        id: 'o1',
        taskId: 't1',
        scheduledDate: windowEnd,
        originalDate: monday,
        windowStart: monday,
        windowEnd: windowEnd,
      );
      final moved = scheduler.rescheduleMissed(
        task: task,
        missed: missed,
        now: DateTime(2026, 7, 10), // well past the window
      );
      expect(moved.scheduledDate, windowEnd);
    });
  });

  group('rescheduleMissed — strict', () {
    test('rolls forward to the next matching weekday after now', () {
      final task = _task(const Recurrence.strict(weekdays: [DateTime.monday]));
      final missed = TaskOccurrence(
        id: occurrenceId('t1', monday),
        taskId: 't1',
        scheduledDate: monday,
        originalDate: monday,
      );
      final moved = scheduler.rescheduleMissed(
        task: task,
        missed: missed,
        now: tuesday,
      );
      expect(moved.status, OccurrenceStatus.rescheduled);
      expect(moved.scheduledDate, DateTime(2026, 7, 6)); // the next Monday
      expect(moved.originalDate, monday);
    });
  });

  group('buildToday — carry overdue forward', () {
    // Today is Wednesday 2026-07-01; an open occurrence sits on Monday.
    final wednesday = DateTime(2026, 7, 1);
    TaskOccurrence overdue(OccurrenceStatus status) => TaskOccurrence(
      id: 'o-mon',
      taskId: 't1',
      scheduledDate: monday,
      originalDate: monday,
      status: status,
    );

    test('carries a past open occurrence onto today as rescheduled', () {
      final task = _task(const Recurrence.flexible());
      final list = scheduler.buildToday(
        tasks: [task],
        today: wednesday,
        existing: [overdue(OccurrenceStatus.pending)],
        carryOverdue: true,
      );
      expect(list, hasLength(1));
      expect(list.single.id, 'o-mon', reason: 'same occurrence, carried');
      expect(list.single.scheduledDate, wednesday);
      expect(list.single.status, OccurrenceStatus.rescheduled);
      expect(list.single.originalDate, monday, reason: 'slip origin preserved');
    });

    test('does not carry forward when carryOverdue is false (agenda mode)', () {
      final task = _task(const Recurrence.flexible());
      final list = scheduler.buildToday(
        tasks: [task],
        today: wednesday,
        existing: [overdue(OccurrenceStatus.pending)],
      );
      expect(list, isEmpty, reason: 'past day left in place for the agenda');
    });

    test('does not carry done or skipped past occurrences', () {
      final task = _task(const Recurrence.flexible());
      for (final status in [OccurrenceStatus.done, OccurrenceStatus.skipped]) {
        final list = scheduler.buildToday(
          tasks: [task],
          today: wednesday,
          existing: [overdue(status)],
          carryOverdue: true,
        );
        expect(list, isEmpty, reason: 'resolved slips are not resurrected');
      }
    });

    test('carries only one occurrence per task and skips regeneration', () {
      // Strict-Wednesday task that ALSO has an overdue Monday occurrence: the
      // carried one wins, today's is not additionally generated.
      final task = _task(
        const Recurrence.strict(weekdays: [DateTime.wednesday]),
      );
      final list = scheduler.buildToday(
        tasks: [task],
        today: wednesday,
        existing: [overdue(OccurrenceStatus.pending)],
        carryOverdue: true,
      );
      expect(list, hasLength(1));
      expect(list.single.id, 'o-mon');
    });
  });

  group('addDays', () {
    test('adds and subtracts calendar days at local midnight', () {
      expect(addDays(DateTime(2026, 6, 29), 1), DateTime(2026, 6, 30));
      expect(addDays(DateTime(2026, 6, 29), -6), DateTime(2026, 6, 23));
      // Time component is normalised away to local midnight.
      expect(addDays(DateTime(2026, 6, 29, 14, 30), 1), DateTime(2026, 6, 30));
    });

    test('rolls across month and year boundaries', () {
      expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
      expect(addDays(DateTime(2026, 1, 1), -1), DateTime(2025, 12, 31));
      expect(addDays(DateTime(2026, 12, 31), 1), DateTime(2027));
      // 2028 is a leap year — 29 Feb exists.
      expect(addDays(DateTime(2028, 2, 28), 1), DateTime(2028, 2, 29));
    });
  });
}
