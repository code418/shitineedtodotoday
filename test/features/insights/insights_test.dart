import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/insights/domain/insights.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

// Fixed reference date: Monday 2026-06-29.
final _now = DateTime(2026, 6, 29);

Task _task({
  required String id,
  required Recurrence recurrence,
  String title = '',
}) => Task(
  id: id,
  ownerId: 'u1',
  title: title,
  recurrence: recurrence,
  createdAt: _now,
  updatedAt: _now,
);

TaskOccurrence _occ({
  required String taskId,
  required DateTime scheduledDate,
  OccurrenceStatus status = OccurrenceStatus.done,
  int? actualDurationMinutes,
}) => TaskOccurrence(
  id: '${taskId}_${scheduledDate.toIso8601String()}',
  taskId: taskId,
  scheduledDate: scheduledDate,
  status: status,
  actualDurationMinutes: actualDurationMinutes,
);

void main() {
  group('computeInsights', () {
    // ── completionRate ──────────────────────────────────────────────────────

    test('completionRate: done vs skipped', () {
      final occs = [
        _occ(taskId: 't1', scheduledDate: _now, status: OccurrenceStatus.done),
        _occ(
          taskId: 't1',
          scheduledDate: _now.subtract(const Duration(days: 1)),
          status: OccurrenceStatus.done,
        ),
        _occ(
          taskId: 't1',
          scheduledDate: _now.subtract(const Duration(days: 2)),
          status: OccurrenceStatus.skipped,
        ),
      ];
      final s = computeInsights(
        occurrences: occs,
        tasks: const [],
        now: _now,
        period: InsightsPeriod.week,
      );
      expect(s.completedCount, 2);
      expect(s.skippedCount, 1);
      expect(s.completionRate, closeTo(2 / 3, 0.001));
    });

    test('completionRate is 0.0 when no done or skipped', () {
      final occs = [
        _occ(
          taskId: 't1',
          scheduledDate: _now,
          status: OccurrenceStatus.pending,
        ),
      ];
      final s = computeInsights(
        occurrences: occs,
        tasks: const [],
        now: _now,
        period: InsightsPeriod.week,
      );
      expect(s.completionRate, 0.0);
    });

    test('zero-occurrence list gives 0.0 completionRate', () {
      final s = computeInsights(
        occurrences: const [],
        tasks: const [],
        now: _now,
        period: InsightsPeriod.week,
      );
      expect(s.completionRate, 0.0);
      expect(s.completedCount, 0);
      expect(s.skippedCount, 0);
    });

    // ── streakDays ──────────────────────────────────────────────────────────

    test('streakDays counts consecutive done days ending today', () {
      // Mon 2026-06-29, Sun 28, Sat 27 — all done; Fri 26 is skipped (breaks streak).
      final occs = [
        _occ(taskId: 't1', scheduledDate: _now), // today — done
        _occ(
          taskId: 't1',
          scheduledDate: _now.subtract(const Duration(days: 1)),
        ), // yesterday — done
        _occ(
          taskId: 't1',
          scheduledDate: _now.subtract(const Duration(days: 2)),
        ), // 2 days ago — done
        _occ(
          taskId: 't1',
          scheduledDate: _now.subtract(const Duration(days: 3)),
          status: OccurrenceStatus.skipped,
        ), // 3 days ago — skipped (not done, breaks streak)
      ];
      final s = computeInsights(
        occurrences: occs,
        tasks: const [],
        now: _now,
        period: InsightsPeriod.week,
      );
      expect(s.streakDays, 3);
    });

    test('streakDays breaks correctly at a gap', () {
      final occs = [
        _occ(taskId: 't1', scheduledDate: _now), // today — done
        // gap: yesterday has nothing done
        _occ(
          taskId: 't1',
          scheduledDate: _now.subtract(const Duration(days: 2)),
        ), // 2 days ago — done
      ];
      final s = computeInsights(
        occurrences: occs,
        tasks: const [],
        now: _now,
        period: InsightsPeriod.week,
      );
      // Streak breaks at yesterday (no done), so streak = 1 (today only).
      expect(s.streakDays, 1);
    });

    test('streakDays is 0 when today has no done occurrence', () {
      final occs = [
        _occ(
          taskId: 't1',
          scheduledDate: _now.subtract(const Duration(days: 1)),
        ), // yesterday — done
      ];
      final s = computeInsights(
        occurrences: occs,
        tasks: const [],
        now: _now,
        period: InsightsPeriod.week,
      );
      expect(s.streakDays, 0);
    });

    // ── totalMinutes ────────────────────────────────────────────────────────

    test('totalMinutes sums actualDurationMinutes for done occs in window', () {
      final occs = [
        _occ(taskId: 't1', scheduledDate: _now, actualDurationMinutes: 30),
        _occ(
          taskId: 't1',
          scheduledDate: _now.subtract(const Duration(days: 1)),
          actualDurationMinutes: 20,
        ),
        // Skipped — should not count.
        _occ(
          taskId: 't1',
          scheduledDate: _now.subtract(const Duration(days: 2)),
          status: OccurrenceStatus.skipped,
          actualDurationMinutes: 99,
        ),
        // Done but null duration — counts as 0.
        _occ(
          taskId: 't1',
          scheduledDate: _now.subtract(const Duration(days: 3)),
        ),
      ];
      final s = computeInsights(
        occurrences: occs,
        tasks: const [],
        now: _now,
        period: InsightsPeriod.week,
      );
      expect(s.totalMinutes, 50); // 30 + 20 + 0
    });

    // ── month window (28 days = 4 × 7) ─────────────────────────────────────

    test('month window is exactly 28 days: 27 days ago included, 28 excluded', () {
      // windowStart = _now - 27 days = 2026-06-02.
      // An occurrence 27 days ago (2026-06-02 = windowStart) must be included.
      // An occurrence 28 days ago (2026-06-01, one day before windowStart) must
      // be excluded. This locks the month rate and the 4-bucket chart to the
      // same 28-day span.
      final inside = _occ(
        taskId: 't1',
        scheduledDate: _now.subtract(const Duration(days: 27)),
        status: OccurrenceStatus.done,
      );
      final outside = _occ(
        taskId: 't2',
        scheduledDate: _now.subtract(const Duration(days: 28)),
        status: OccurrenceStatus.done,
      );
      final s = computeInsights(
        occurrences: [inside, outside],
        tasks: const [],
        now: _now,
        period: InsightsPeriod.month,
      );
      // Only the 27-days-ago occurrence is in window.
      expect(s.completedCount, 1);
    });

    test('month window crossing a month boundary tiles correctly', () {
      // now = 10 Mar 2026 → windowStart = 11 Feb 2026 (day offset normalises
      // back across the month boundary). Verifies the calendar-based day math.
      final now = DateTime(2026, 3, 10);
      final atStart = _occ(
        taskId: 't1',
        scheduledDate: DateTime(2026, 2, 11), // windowStart, inclusive
      );
      final justBefore = _occ(
        taskId: 't2',
        scheduledDate: DateTime(2026, 2, 10), // one day before window
      );
      final s = computeInsights(
        occurrences: [atStart, justBefore],
        tasks: const [],
        now: now,
        period: InsightsPeriod.month,
      );
      expect(s.completedCount, 1, reason: 'only the windowStart day is in');
      // Every done occurrence in window lands in exactly one bucket, so the
      // bucket total equals completedCount (no day falls through a seam).
      final bucketTotal = s.buckets.fold<int>(0, (sum, b) => sum + b.doneCount);
      expect(bucketTotal, s.completedCount);
    });

    // ── week buckets ────────────────────────────────────────────────────────

    test('week buckets have length 7 and counts land on the right weekday', () {
      // _now is Monday 2026-06-29 (weekday 1).
      // Window: Tue 2026-06-23 .. Mon 2026-06-29 (today - 6 days = Tue).
      // bucket[0] = Tue 2026-06-23, bucket[1] = Wed 2026-06-24, ..., bucket[6] = Mon 2026-06-29.
      final wed = _now.subtract(const Duration(days: 5)); // 2026-06-24 = Wed
      expect(wed.weekday, 3); // Wednesday
      final occs = [
        _occ(taskId: 't1', scheduledDate: wed),
        _occ(taskId: 't2', scheduledDate: wed),
        _occ(taskId: 't1', scheduledDate: _now), // Monday = bucket[6]
      ];
      final s = computeInsights(
        occurrences: occs,
        tasks: const [],
        now: _now,
        period: InsightsPeriod.week,
      );
      expect(s.buckets.length, 7);
      // bucket[0] = Tue 2026-06-23, bucket[1] = Wed 2026-06-24, bucket[6] = Mon 2026-06-29.
      expect(s.buckets[0].label, 'Tue');
      expect(s.buckets[0].doneCount, 0);
      expect(s.buckets[1].label, 'Wed');
      expect(s.buckets[1].doneCount, 2);
      expect(s.buckets[6].label, 'Mon');
      expect(s.buckets[6].doneCount, 1);
    });

    // ── slips ───────────────────────────────────────────────────────────────

    test('slips are sorted desc by skip count and capped at 3', () {
      // Task t1 = 4 skips, t2 = 2 skips, t3 = 3 skips, t4 = 1 skip.
      // Expected order: t1(4), t3(3), t2(2). t4 is cut off.
      final occs = [
        for (var i = 0; i < 4; i++)
          _occ(
            taskId: 't1',
            scheduledDate: _now.subtract(Duration(days: i)),
            status: OccurrenceStatus.skipped,
          ),
        for (var i = 0; i < 2; i++)
          _occ(
            taskId: 't2',
            scheduledDate: _now.subtract(Duration(days: i)),
            status: OccurrenceStatus.skipped,
          ),
        for (var i = 0; i < 3; i++)
          _occ(
            taskId: 't3',
            scheduledDate: _now.subtract(Duration(days: i)),
            status: OccurrenceStatus.skipped,
          ),
        _occ(
          taskId: 't4',
          scheduledDate: _now,
          status: OccurrenceStatus.skipped,
        ),
      ];
      final s = computeInsights(
        occurrences: occs,
        tasks: const [],
        now: _now,
        period: InsightsPeriod.week,
      );
      expect(s.slips.length, 3);
      expect(s.slips[0].taskId, 't1');
      expect(s.slips[0].skips, 4);
      expect(s.slips[1].taskId, 't3');
      expect(s.slips[1].skips, 3);
      expect(s.slips[2].taskId, 't2');
      expect(s.slips[2].skips, 2);
    });

    // ── suggestion ──────────────────────────────────────────────────────────

    test(
      'suggestion proposes flexible for the top strict-recurrence slipper',
      () {
        final strictTask = _task(
          id: 't1',
          recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
          title: 'Vacuum',
        );
        final occs = [
          for (var i = 0; i < 3; i++)
            _occ(
              taskId: 't1',
              scheduledDate: _now.subtract(Duration(days: i)),
              status: OccurrenceStatus.skipped,
            ),
        ];
        final s = computeInsights(
          occurrences: occs,
          tasks: [strictTask],
          now: _now,
          period: InsightsPeriod.week,
        );
        expect(s.suggestion, isNotNull);
        expect(s.suggestion!.taskId, 't1');
        expect(s.suggestion!.suggestedRecurrence, isA<FlexibleRecurrence>());
      },
    );

    test(
      'suggestion is null when the slipper already has flexible recurrence',
      () {
        final flexTask = _task(
          id: 't1',
          recurrence: const Recurrence.flexible(period: FrequencyPeriod.week),
          title: 'Walk dog',
        );
        final occs = [
          for (var i = 0; i < 3; i++)
            _occ(
              taskId: 't1',
              scheduledDate: _now.subtract(Duration(days: i)),
              status: OccurrenceStatus.skipped,
            ),
        ];
        final s = computeInsights(
          occurrences: occs,
          tasks: [flexTask],
          now: _now,
          period: InsightsPeriod.week,
        );
        expect(s.suggestion, isNull);
      },
    );

    test('suggestion is non-null for strict slipper with empty title', () {
      // Verifies the domain still produces a suggestion even with an empty
      // task title (the message is now built in the presentation layer).
      final strictTask = _task(
        id: 't1',
        recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
      );
      final occs = [
        _occ(
          taskId: 't1',
          scheduledDate: _now,
          status: OccurrenceStatus.skipped,
        ),
      ];
      final s = computeInsights(
        occurrences: occs,
        tasks: [strictTask],
        now: _now,
        period: InsightsPeriod.week,
      );
      expect(s.suggestion, isNotNull);
      expect(s.suggestion!.taskId, 't1');
      expect(s.suggestion!.suggestedRecurrence, isA<FlexibleRecurrence>());
    });
  });
}
