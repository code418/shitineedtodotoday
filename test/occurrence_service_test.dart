import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/tasks/application/occurrence_service.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/forgiving_scheduler.dart';
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
}

final _monday = DateTime(2026, 6, 29);
final _earlier = DateTime(2026, 6, 22);
