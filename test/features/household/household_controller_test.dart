import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/household/application/household_providers.dart';
import 'package:snitd/features/household/data/household_repository.dart';
import 'package:snitd/features/household/domain/household.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

class _RecordingHouseholdRepository implements HouseholdRepository {
  Household? saved;
  @override
  Stream<Household> watch(String ownerId) => Stream.value(Household.empty);
  @override
  Future<void> save(String ownerId, Household household) async =>
      saved = household;
}

class _RecordingTaskRepository implements TaskRepository {
  final List<Task> upserts = [];
  @override
  Stream<List<Task>> watchTasks(String ownerId) => Stream.value(const <Task>[]);
  @override
  Future<void> upsert(Task task) async => upserts.add(task);
  @override
  Future<void> delete(String ownerId, String taskId) async {}
  @override
  String newId(String ownerId) => 'x';
}

Task _task(String id, {String? assigneeId}) => Task(
  id: id,
  ownerId: 'u1',
  title: id,
  recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
  assigneeId: assigneeId,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  test(
    'removeMember clears assigneeId on that member\'s tasks and drops the member',
    () async {
      final householdRepo = _RecordingHouseholdRepository();
      final taskRepo = _RecordingTaskRepository();
      final controller = HouseholdController(
        repository: householdRepo,
        taskRepository: taskRepo,
        ownerId: 'u1',
        idGen: () => 'unused',
        now: () => DateTime(2026, 7, 1, 9),
      );

      const household = Household(
        members: [
          HouseholdMember(id: 'm_1', name: 'Sam'),
          HouseholdMember(id: 'm_2', name: 'Alex'),
        ],
      );
      final tasks = [
        _task('t1', assigneeId: 'm_1'), // assigned to the removed member
        _task('t2', assigneeId: 'm_2'), // someone else — untouched
        _task('t3'), // unassigned — untouched
      ];

      await controller.removeMember(household, 'm_1', tasks: tasks);

      // Only t1 was rewritten, with its assignee cleared and updatedAt bumped.
      expect(taskRepo.upserts.length, 1);
      expect(taskRepo.upserts.single.id, 't1');
      expect(taskRepo.upserts.single.assigneeId, isNull);
      expect(taskRepo.upserts.single.updatedAt, DateTime(2026, 7, 1, 9));

      // The household was saved without Sam, keeping Alex.
      expect(householdRepo.saved!.members.map((m) => m.id), ['m_2']);
    },
  );

  test(
    'removeMember writes no task when nobody was assigned to the member',
    () async {
      final householdRepo = _RecordingHouseholdRepository();
      final taskRepo = _RecordingTaskRepository();
      final controller = HouseholdController(
        repository: householdRepo,
        taskRepository: taskRepo,
        ownerId: 'u1',
        idGen: () => 'unused',
        now: () => DateTime(2026, 7, 1, 9),
      );

      const household = Household(
        members: [HouseholdMember(id: 'm_1', name: 'Sam')],
      );

      await controller.removeMember(
        household,
        'm_1',
        tasks: [
          _task('t1', assigneeId: 'm_2'),
          _task('t2'),
        ],
      );

      expect(taskRepo.upserts, isEmpty);
      expect(householdRepo.saved!.members, isEmpty);
    },
  );
}
