import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/schedule/domain/agenda.dart';
import 'package:snitd/features/tasks/domain/scheduling/forgiving_scheduler.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

Task _task({required String id, required Recurrence recurrence}) => Task(
  id: id,
  ownerId: 'u1',
  title: 'Test task $id',
  recurrence: recurrence,
  estimatedEffortMinutes: 15,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  // ── weekStartFor ────────────────────────────────────────────────────────────
  group('weekStartFor', () {
    // Week: Mon 29 Jun 2026 – Sun 5 Jul 2026.
    final monday = DateTime(2026, 6, 29);
    final wednesday = DateTime(2026, 7, 1);
    final sunday = DateTime(2026, 7, 5);

    test('returns Monday itself when given a Monday', () {
      expect(weekStartFor(monday), monday);
    });

    test('returns the preceding Monday for a Wednesday', () {
      expect(weekStartFor(wednesday), monday);
    });

    test('returns the preceding Monday for a Sunday', () {
      expect(weekStartFor(sunday), monday);
    });

    test('strips time from the result', () {
      final withTime = DateTime(2026, 6, 29, 14, 30);
      expect(weekStartFor(withTime), DateTime(2026, 6, 29));
    });
  });

  // ── buildWeekAgenda ─────────────────────────────────────────────────────────
  group('buildWeekAgenda', () {
    const scheduler = ForgivingScheduler();
    final weekStart = DateTime(2026, 6, 29); // Mon 29 Jun 2026

    test('always returns exactly 7 AgendaDays', () {
      final agenda = buildWeekAgenda(
        scheduler: scheduler,
        tasks: const [],
        existing: const [],
        weekStart: weekStart,
      );
      expect(agenda.length, 7);
    });

    test('days are consecutive and start on Monday', () {
      final agenda = buildWeekAgenda(
        scheduler: scheduler,
        tasks: const [],
        existing: const [],
        weekStart: weekStart,
      );
      for (var i = 0; i < 7; i++) {
        expect(
          agenda[i].date,
          weekStart.add(Duration(days: i)),
          reason: 'day $i should be ${weekStart.add(Duration(days: i))}',
        );
      }
    });

    test('strict Monday task appears only on the Monday slot', () {
      final task = _task(
        id: 'monday_task',
        recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
      );
      final agenda = buildWeekAgenda(
        scheduler: scheduler,
        tasks: [task],
        existing: const [],
        weekStart: weekStart,
      );

      // Monday (index 0) has the task.
      expect(agenda[0].occurrences, hasLength(1));
      expect(agenda[0].occurrences.first.taskId, 'monday_task');

      // All other days are empty.
      for (var i = 1; i < 7; i++) {
        expect(
          agenda[i].occurrences,
          isEmpty,
          reason: 'day $i should have no occurrences for a Monday-only task',
        );
      }
    });

    test('drops orphan occurrences but keeps occurrences for live tasks', () {
      final liveTask = _task(
        id: 'live',
        recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
      );
      // An occurrence whose task has been deleted — buildToday would otherwise
      // carry it as a same-day existing occurrence and the agenda would render
      // a row labelled by the raw taskId.
      final orphan = TaskOccurrence(
        id: 'ghost_2026-06-29',
        taskId: 'ghost',
        scheduledDate: DateTime(2026, 6, 29), // Monday slot
      );
      final agenda = buildWeekAgenda(
        scheduler: scheduler,
        tasks: [liveTask],
        existing: [orphan],
        weekStart: weekStart,
      );

      // Monday holds only the live task's occurrence; the orphan is filtered.
      expect(agenda[0].occurrences, hasLength(1));
      expect(agenda[0].occurrences.first.taskId, 'live');
    });

    test('flexible-weekly task appears on the week-start (Monday) slot', () {
      final task = _task(
        id: 'flex_task',
        recurrence: const Recurrence.flexible(
          timesPerPeriod: 1,
          period: FrequencyPeriod.week,
          windowDays: 7,
        ),
      );
      final agenda = buildWeekAgenda(
        scheduler: scheduler,
        tasks: [task],
        existing: const [],
        weekStart: weekStart,
      );

      // ForgivingScheduler anchors the first occurrence of a weekly flex task
      // at offset 0 within the period, which is Monday.
      expect(agenda[0].occurrences, hasLength(1));
      expect(agenda[0].occurrences.first.taskId, 'flex_task');
    });
  });
}
