import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/tasks/application/occurrence_service.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/forgiving_scheduler.dart';
import 'package:snitd/features/tasks/domain/scheduling/load_balancer.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

import 'task_service_test.dart' show FakeTaskRepository;

class FakeOccurrenceRepository implements OccurrenceRepository {
  final Map<String, TaskOccurrence> store = {};

  @override
  Stream<List<TaskOccurrence>> watchOccurrences(String ownerId) =>
      Stream.value(store.values.toList());

  @override
  Future<void> upsert(String ownerId, TaskOccurrence occurrence) async =>
      store[occurrence.id] = occurrence;

  @override
  Future<void> delete(String ownerId, String occurrenceId) async =>
      store.remove(occurrenceId);

  @override
  Future<void> deleteForTask(String ownerId, String taskId) async =>
      store.removeWhere((_, o) => o.taskId == taskId);
}

Task _task({int estimate = 15}) => Task(
  id: 't1',
  ownerId: 'u1',
  title: 'Wash bedding',
  recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
  estimatedEffortMinutes: estimate,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late FakeOccurrenceRepository occRepo;
  late FakeTaskRepository taskRepo;
  late OccurrenceService service;
  final clock = DateTime(2026, 6, 29, 9);

  setUp(() {
    occRepo = FakeOccurrenceRepository();
    taskRepo = FakeTaskRepository();
    service = OccurrenceService(
      occurrences: occRepo,
      tasks: taskRepo,
      scheduler: const ForgivingScheduler(),
      ownerId: 'u1',
      now: () => clock,
    );
  });

  TaskOccurrence pending() =>
      TaskOccurrence(id: 't1_2026-06-29', taskId: 't1', scheduledDate: _monday);

  test(
    'complete records duration and re-bases the estimate (learns lower)',
    () async {
      final task = _task(estimate: 15);
      final result = await service.complete(
        occurrence: pending(),
        task: task,
        actualMinutes: 10,
      );

      expect(result.occurrence.status, OccurrenceStatus.done);
      expect(result.occurrence.completedAt, clock);
      expect(result.occurrence.actualDurationMinutes, 10);
      expect(occRepo.store['t1_2026-06-29']!.status, OccurrenceStatus.done);

      // Effort learning: mean([10]) -> 10, below the 15 estimate, so re-based.
      expect(result.updatedTask, isNotNull);
      expect(result.updatedTask!.estimatedEffortMinutes, 10);
      expect(taskRepo.store['t1']!.estimatedEffortMinutes, 10);
    },
  );

  test('complete leaves the estimate untouched when learning agrees', () async {
    final task = _task(estimate: 10);
    final result = await service.complete(
      occurrence: pending(),
      task: task,
      actualMinutes: 10,
    );
    expect(result.updatedTask, isNull);
    expect(taskRepo.store, isEmpty); // task not re-written
  });

  test('complete blends prior history into the learned estimate', () async {
    final task = _task(estimate: 15);
    final history = [
      TaskOccurrence(
        id: 'h1',
        taskId: 't1',
        scheduledDate: _earlier,
        status: OccurrenceStatus.done,
        completedAt: _earlier,
        actualDurationMinutes: 20,
      ),
    ];
    final result = await service.complete(
      occurrence: pending(),
      task: task,
      actualMinutes: 10,
      history: history,
    );
    // mean([20, 10]) = 15 -> stays 15, no change.
    expect(result.updatedTask, isNull);
  });

  test('skip marks the occurrence skipped, never failed', () async {
    final skipped = await service.skip(pending());
    expect(skipped.status, OccurrenceStatus.skipped);
    expect(occRepo.store['t1_2026-06-29']!.status, OccurrenceStatus.skipped);
  });

  test(
    'reschedule moves a missed strict occurrence to the next slot',
    () async {
      final task = _task();
      final tuesday = DateTime(2026, 6, 30, 9);
      final svc = OccurrenceService(
        occurrences: occRepo,
        tasks: taskRepo,
        scheduler: const ForgivingScheduler(),
        ownerId: 'u1',
        now: () => tuesday,
      );
      final moved = await svc.reschedule(task: task, occurrence: pending());
      expect(moved.status, OccurrenceStatus.rescheduled);
      expect(moved.scheduledDate, DateTime(2026, 7, 6)); // next Monday
      expect(occRepo.store[moved.id]!.status, OccurrenceStatus.rescheduled);
    },
  );

  test(
    'reopen clears completedAt, actualDurationMinutes and sets pending',
    () async {
      final done = TaskOccurrence(
        id: 't1_2026-06-29',
        taskId: 't1',
        scheduledDate: _monday,
        status: OccurrenceStatus.done,
        completedAt: clock,
        actualDurationMinutes: 12,
      );
      occRepo.store[done.id] = done;

      final result = await service.reopen(done);
      final reopened = result.occurrence;

      expect(reopened.status, OccurrenceStatus.pending);
      expect(reopened.completedAt, isNull);
      expect(reopened.actualDurationMinutes, isNull);
      expect(occRepo.store[done.id]!.status, OccurrenceStatus.pending);
    },
  );

  test(
    'reopen re-bases the estimate down from the remaining actuals',
    () async {
      // Prior completions averaged ~10m, then a 120m fat-finger pushed it up.
      final prior = [
        TaskOccurrence(
          id: 't1_2026-06-15',
          taskId: 't1',
          scheduledDate: DateTime(2026, 6, 15),
          status: OccurrenceStatus.done,
          completedAt: DateTime(2026, 6, 15, 10),
          actualDurationMinutes: 10,
        ),
        TaskOccurrence(
          id: 't1_2026-06-22',
          taskId: 't1',
          scheduledDate: DateTime(2026, 6, 22),
          status: OccurrenceStatus.done,
          completedAt: DateTime(2026, 6, 22, 10),
          actualDurationMinutes: 10,
        ),
      ];
      final fatFinger = TaskOccurrence(
        id: 't1_2026-06-29',
        taskId: 't1',
        scheduledDate: _monday,
        status: OccurrenceStatus.done,
        completedAt: clock,
        actualDurationMinutes: 120,
      );
      // Task estimate currently reflects the inflated mean.
      final task = _task(estimate: 45);

      final result = await service.reopen(
        fatFinger,
        task: task,
        history: [...prior, fatFinger],
      );

      // Estimate relearns from the remaining 10/10 actuals → back to ~10m.
      expect(result.updatedTask, isNotNull);
      expect(result.updatedTask!.estimatedEffortMinutes, 10);
      expect(result.updatedTask!.updatedAt, clock);
      expect(taskRepo.store['t1']!.estimatedEffortMinutes, 10);
    },
  );

  test('reopen leaves the estimate untouched when no actuals remain', () async {
    final only = TaskOccurrence(
      id: 't1_2026-06-29',
      taskId: 't1',
      scheduledDate: _monday,
      status: OccurrenceStatus.done,
      completedAt: clock,
      actualDurationMinutes: 120,
    );
    final task = _task(estimate: 120);

    final result = await service.reopen(only, task: task, history: [only]);

    // Nothing left to relearn from → estimate unchanged, no task write.
    expect(result.updatedTask, isNull);
    expect(taskRepo.store.containsKey('t1'), isFalse);
  });

  // ---------------------------------------------------------------------------
  // rebalanceOpen — overwhelm reset
  // ---------------------------------------------------------------------------
  group('rebalanceOpen', () {
    // 3 flexible-weekly tasks, 40 min each, all on Monday (window Mon–Sun).
    // Budget = 60 → at most 1 task (40 min) fits on Monday;
    // the other two must be moved to later days.
    final windowStart = DateTime(2026, 6, 29); // Mon 29 Jun
    final windowEnd = DateTime(2026, 7, 5); // Sun  5 Jul

    Task flexTask(String id) => Task(
      id: id,
      ownerId: 'u1',
      title: 'Flex task $id',
      recurrence: const Recurrence.flexible(
        timesPerPeriod: 1,
        period: FrequencyPeriod.week,
        windowDays: 7,
      ),
      estimatedEffortMinutes: 40,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    TaskOccurrence openOcc(String taskId) => TaskOccurrence(
      id: '${taskId}_2026-06-29',
      taskId: taskId,
      scheduledDate: windowStart,
      windowStart: windowStart,
      windowEnd: windowEnd,
      status: OccurrenceStatus.pending,
    );

    test(
      'spreads over-budget occurrences across the week and persists moves',
      () async {
        final localOccRepo = FakeOccurrenceRepository();
        final localTaskRepo = FakeTaskRepository();
        final svc = OccurrenceService(
          occurrences: localOccRepo,
          tasks: localTaskRepo,
          scheduler: const ForgivingScheduler(),
          ownerId: 'u1',
          now: () => DateTime(2026, 6, 29, 9),
        );

        final tasks = ['t1', 't2', 't3'].map(flexTask).toList();
        final open = ['t1', 't2', 't3'].map(openOcc).toList();

        // Seed repo with the original open occurrences on Monday.
        for (final o in open) {
          localOccRepo.store[o.id] = o;
        }

        final result = await svc.rebalanceOpen(
          open: open,
          tasks: tasks,
          dailyBudgetMinutes: 60,
          horizonDays: 7,
        );

        // At least one occurrence must have moved to a later day.
        expect(
          result.any(
            (o) =>
                o.status == OccurrenceStatus.rescheduled &&
                o.scheduledDate != windowStart,
          ),
          isTrue,
          reason: 'some occurrences should have been rescheduled off Monday',
        );

        // Monday's persisted open load must be ≤ budget.
        final estimate = {
          for (final t in tasks) t.id: t.estimatedEffortMinutes,
        };
        final mondayLoad = loadForDay(
          localOccRepo.store.values,
          estimate,
          windowStart,
        );
        expect(
          mondayLoad,
          lessThanOrEqualTo(60),
          reason: "Monday's persisted load should be within the budget",
        );
      },
    );

    test(
      'a movable today-occurrence is not placed on a future day already at budget',
      () async {
        // Regression for the overwhelm-reset screen fix: passing the full week's
        // open occurrences (including a strict one at budget on Tuesday) must
        // keep the flexible item off that full day.
        final monday = DateTime(2026, 6, 29);
        final tuesday = DateTime(2026, 6, 30);

        // Strict task: 60 min, locked to Tuesday — fills the 60-min budget.
        final strictTask = Task(
          id: 't2',
          ownerId: 'u1',
          title: 'Strict Tuesday',
          recurrence: const Recurrence.strict(weekdays: [DateTime.tuesday]),
          estimatedEffortMinutes: 60,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );

        // Flexible task: 40 min — the one being rebalanced.
        final flexTaskA = Task(
          id: 't1',
          ownerId: 'u1',
          title: 'Flexible',
          recurrence: const Recurrence.flexible(
            timesPerPeriod: 1,
            period: FrequencyPeriod.week,
            windowDays: 7,
          ),
          estimatedEffortMinutes: 40,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );
        // A second flexible task to push Monday over the 60-min budget.
        final flexTaskB = flexTaskA.copyWith(id: 't3', title: 'Flex 2');

        final strictOcc = TaskOccurrence(
          id: 't2_2026-06-30',
          taskId: 't2',
          scheduledDate: tuesday,
          status: OccurrenceStatus.pending,
        );
        final flexOcc1 = TaskOccurrence(
          id: 't1_2026-06-29',
          taskId: 't1',
          scheduledDate: monday,
          windowStart: monday,
          windowEnd: DateTime(2026, 7, 5),
          status: OccurrenceStatus.pending,
        );
        final flexOcc2 = TaskOccurrence(
          id: 't3_2026-06-29',
          taskId: 't3',
          scheduledDate: monday,
          windowStart: monday,
          windowEnd: DateTime(2026, 7, 5),
          status: OccurrenceStatus.pending,
        );

        final localOccRepo = FakeOccurrenceRepository();
        final localTaskRepo = FakeTaskRepository();
        final svc = OccurrenceService(
          occurrences: localOccRepo,
          tasks: localTaskRepo,
          scheduler: const ForgivingScheduler(),
          ownerId: 'u1',
          now: () => DateTime(2026, 6, 29, 9),
        );

        final tasks = [strictTask, flexTaskA, flexTaskB];
        // Simulate the screen passing the full week's open occurrences.
        final open = [strictOcc, flexOcc1, flexOcc2];

        final result = await svc.rebalanceOpen(
          open: open,
          tasks: tasks,
          dailyBudgetMinutes: 60,
        );

        // Find the occurrence(s) that were moved off Monday.
        final movedOffMonday = result.where(
          (o) => o.taskId != 't2' && o.scheduledDate != monday,
        );
        // At least one flexible occurrence must have been moved off Monday.
        expect(
          movedOffMonday.isNotEmpty,
          isTrue,
          reason: 'some flex occurrences should be rescheduled off Monday',
        );
        // None of the moved flexible occurrences should land on Tuesday —
        // the strict task already fills the 60-min budget there.
        expect(
          movedOffMonday.every((o) => o.scheduledDate != tuesday),
          isTrue,
          reason: 'Tuesday is at budget; flex occurrence must skip it',
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // moveTo — drag-to-reschedule
  // ---------------------------------------------------------------------------
  group('moveTo', () {
    test(
      'moves occurrence to the target day, marks rescheduled, preserves originalDate',
      () async {
        final monday = DateTime(2026, 6, 29);
        final thursday = DateTime(2026, 7, 2, 14, 30); // has time component
        final occ = TaskOccurrence(
          id: 't1_2026-06-29',
          taskId: 't1',
          scheduledDate: monday,
        );

        final moved = await service.moveTo(occ, thursday);

        // scheduledDate is date-only Thursday.
        expect(moved.scheduledDate, DateTime(2026, 7, 2));
        expect(moved.status, OccurrenceStatus.rescheduled);
        // originalDate is preserved from Monday.
        expect(moved.originalDate, monday);
        // Pinned so a later rebalance leaves it on the chosen day.
        expect(moved.pinned, isTrue);
        // Persisted.
        expect(occRepo.store[moved.id]!.scheduledDate, DateTime(2026, 7, 2));
        expect(occRepo.store[moved.id]!.pinned, isTrue);
      },
    );

    test(
      'preserves an existing originalDate when moving a previously moved occurrence',
      () async {
        final originalMonday = DateTime(2026, 6, 22);
        final wednesday = DateTime(2026, 6, 24);
        final friday = DateTime(2026, 6, 26);
        // Already moved once — originalDate is set.
        final alreadyMoved = TaskOccurrence(
          id: 't1_2026-06-24',
          taskId: 't1',
          scheduledDate: wednesday,
          originalDate: originalMonday,
          status: OccurrenceStatus.rescheduled,
        );

        final moved = await service.moveTo(alreadyMoved, friday);

        // originalDate should stay as the original Monday, not overwritten.
        expect(moved.originalDate, originalMonday);
        expect(moved.scheduledDate, DateTime(2026, 6, 26));
      },
    );
  });
}

final _monday = DateTime(2026, 6, 29);
final _earlier = DateTime(2026, 6, 22);
