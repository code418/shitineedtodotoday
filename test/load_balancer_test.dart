import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/tasks/domain/scheduling/load_balancer.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

final monday = DateTime(2026, 6, 29);

Task _task(
  String id, {
  required int minutes,
  Recurrence recurrence = const Recurrence.flexible(
    period: FrequencyPeriod.week,
  ),
}) => Task(
  id: id,
  ownerId: 'u1',
  title: id,
  recurrence: recurrence,
  estimatedEffortMinutes: minutes,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

TaskOccurrence _occ(
  String taskId, {
  required DateTime on,
  DateTime? windowStart,
  DateTime? windowEnd,
}) => TaskOccurrence(
  id: '${taskId}_x',
  taskId: taskId,
  scheduledDate: on,
  originalDate: on,
  windowStart: windowStart ?? monday,
  windowEnd: windowEnd ?? monday.add(const Duration(days: 6)),
);

int _loadOn(List<TaskOccurrence> occ, Map<String, int> est, DateTime day) =>
    loadForDay(occ, est, day);

void main() {
  group('loadForDay', () {
    test('sums open occurrences on the day, ignoring done and other days', () {
      final est = {'a': 15, 'b': 10, 'c': 20};
      final occ = [
        _occ('a', on: monday),
        _occ('b', on: monday),
        _occ('c', on: monday).copyWith(status: OccurrenceStatus.done),
        _occ('a', on: monday.add(const Duration(days: 1))),
      ];
      expect(_loadOn(occ, est, monday), 25); // a + b; c done; the 2nd a is Tue
    });
  });

  group('rebalance', () {
    test('packs flexible tasks day-by-day up to the budget', () {
      final tasks = [
        _task('a', minutes: 30),
        _task('b', minutes: 30),
        _task('c', minutes: 30),
        _task('d', minutes: 30),
      ];
      final occ = [for (final t in tasks) _occ(t.id, on: monday)];
      final est = {for (final t in tasks) t.id: t.estimatedEffortMinutes};

      final result = rebalance(
        occurrences: occ,
        tasks: tasks,
        from: monday,
        horizonDays: 7,
        dailyBudgetMinutes: 60,
      );

      // Earliest-with-room packs two 30m tasks onto Monday, two onto Tuesday.
      expect(_loadOn(result, est, monday), 60);
      expect(_loadOn(result, est, monday.add(const Duration(days: 1))), 60);
    });

    test('keeps strict tasks fixed and flows flexible load around them', () {
      final strict = _task(
        'fixed',
        minutes: 40,
        recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
      );
      final flex = _task('flex', minutes: 30);
      final tasks = [strict, flex];
      final est = {for (final t in tasks) t.id: t.estimatedEffortMinutes};
      final occ = [_occ('fixed', on: monday), _occ('flex', on: monday)];

      final result = rebalance(
        occurrences: occ,
        tasks: tasks,
        from: monday,
        horizonDays: 7,
        dailyBudgetMinutes: 60,
      );

      // Monday already has the fixed 40m; 40+30 > 60, so flex flows to Tuesday.
      expect(_loadOn(result, est, monday), 40);
      expect(_loadOn(result, est, monday.add(const Duration(days: 1))), 30);
      // The strict occurrence stayed put and unchanged.
      final fixedOcc = result.firstWhere((o) => o.taskId == 'fixed');
      expect(fixedOcc.scheduledDate, monday);
      expect(fixedOcc.status, OccurrenceStatus.pending);
    });

    test(
      'moved occurrences become rescheduled and keep their original date',
      () {
        final tasks = [_task('a', minutes: 50), _task('b', minutes: 50)];
        final occ = [_occ('a', on: monday), _occ('b', on: monday)];

        final result = rebalance(
          occurrences: occ,
          tasks: tasks,
          from: monday,
          horizonDays: 7,
          dailyBudgetMinutes: 60,
        );

        // a fits Monday (50<=60); b can't (50+50>60) so it moves to Tuesday.
        final b = result.firstWhere((o) => o.taskId == 'b');
        expect(b.status, OccurrenceStatus.rescheduled);
        expect(b.scheduledDate, monday.add(const Duration(days: 1)));
        expect(b.originalDate, monday);
        final a = result.firstWhere((o) => o.taskId == 'a');
        expect(a.status, OccurrenceStatus.pending); // unchanged
      },
    );

    test('respects an occurrence window when placing', () {
      // Its window only allows Wed–Thu, so it cannot land on Mon/Tue.
      final wed = monday.add(const Duration(days: 2));
      final thu = monday.add(const Duration(days: 3));
      final tasks = [_task('a', minutes: 30)];
      final est = {'a': 30};
      final occ = [_occ('a', on: monday, windowStart: wed, windowEnd: thu)];

      final result = rebalance(
        occurrences: occ,
        tasks: tasks,
        from: monday,
        horizonDays: 7,
        dailyBudgetMinutes: 60,
      );

      final a = result.single;
      expect(a.scheduledDate, wed); // earliest day in its window
      expect(_loadOn(result, est, monday), 0);
    });

    test('does not move a pinned occurrence', () {
      final tasks = [_task('a', minutes: 30), _task('pinned', minutes: 30)];
      final wed = monday.add(const Duration(days: 2));
      final occ = [
        _occ('a', on: monday),
        _occ('pinned', on: wed).copyWith(pinned: true),
      ];

      final result = rebalance(
        occurrences: occ,
        tasks: tasks,
        from: monday,
        horizonDays: 7,
        dailyBudgetMinutes: 60,
      );

      // Without the pin, 'pinned' would pack onto Monday (room under budget);
      // pinned, it stays on the day the user chose.
      final pinned = result.firstWhere((o) => o.taskId == 'pinned');
      expect(pinned.scheduledDate, wed);
      expect(pinned.status, OccurrenceStatus.pending, reason: 'untouched');
    });

    test('over capacity still spreads to the least-loaded days', () {
      // Three 60m tasks, budget 60, 2-day horizon: no day has room for a third,
      // so it lands on the least-loaded day rather than stacking.
      final tasks = [
        _task('a', minutes: 60),
        _task('b', minutes: 60),
        _task('c', minutes: 60),
      ];
      final est = {for (final t in tasks) t.id: 60};
      final occ = [for (final t in tasks) _occ(t.id, on: monday)];

      final result = rebalance(
        occurrences: occ,
        tasks: tasks,
        from: monday,
        horizonDays: 2,
        dailyBudgetMinutes: 60,
      );

      final tue = monday.add(const Duration(days: 1));
      final loads = [_loadOn(result, est, monday), _loadOn(result, est, tue)];
      loads.sort();
      expect(loads, [60, 120]); // one day doubles up; nothing is dropped
    });

    test('never moves a done occurrence, even off an over-budget day', () {
      final tasks = [
        _task(
          'fixed',
          minutes: 50,
          recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
        ),
        _task('done', minutes: 30), // flexible — would otherwise be movable
      ];
      // Monday is already at budget from the fixed task; a flexible *open*
      // occurrence here would be pushed to Tuesday. A done one must not be.
      final fixedOcc = _occ('fixed', on: monday);
      final doneOcc = _occ('done', on: monday).copyWith(
        status: OccurrenceStatus.done,
        completedAt: DateTime(2026, 6, 29, 10),
        actualDurationMinutes: 30,
      );

      final result = rebalance(
        occurrences: [fixedOcc, doneOcc],
        tasks: tasks,
        from: monday,
        horizonDays: 7,
        dailyBudgetMinutes: 50,
      );

      final outDone = result.firstWhere((o) => o.taskId == 'done');
      expect(outDone.scheduledDate, monday, reason: 'done must stay put');
      expect(outDone.status, OccurrenceStatus.done, reason: 'and stays done');
    });
  });
}
