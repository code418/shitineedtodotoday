import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/tasks/application/task_service.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';
import 'package:snitd/features/tasks/domain/task_suggestion.dart';

class FakeTaskRepository implements TaskRepository {
  final Map<String, Task> store = {};
  int _seq = 0;

  @override
  Stream<List<Task>> watchTasks(String ownerId) =>
      Stream.value(store.values.where((t) => t.ownerId == ownerId).toList());

  @override
  Future<void> upsert(Task task) async => store[task.id] = task;

  @override
  Future<void> delete(String ownerId, String taskId) async =>
      store.remove(taskId);

  @override
  String newId(String ownerId) => 'task-${_seq++}';
}

void main() {
  late FakeTaskRepository repo;
  late TaskService service;
  final clock = DateTime(2026, 6, 29, 9);

  setUp(() {
    repo = FakeTaskRepository();
    service = TaskService(repository: repo, ownerId: 'u1', now: () => clock);
  });

  test('addTask persists a trimmed, owned, timestamped task', () async {
    final task = await service.addTask(
      title: '  Wash bedding  ',
      recurrence: const Recurrence.strict(weekdays: [DateTime.wednesday]),
      category: 'Kitchen & Bedding',
      estimatedEffortMinutes: 10,
    );
    expect(task.id, 'task-0');
    expect(task.title, 'Wash bedding');
    expect(task.ownerId, 'u1');
    expect(task.category, 'Kitchen & Bedding');
    expect(task.estimatedEffortMinutes, 10);
    expect(task.createdAt, clock);
    expect(task.updatedAt, clock);
    expect(repo.store['task-0'], task);
  });

  test('addFromSuggestion materialises a starter into a real task', () async {
    const suggestion = TaskSuggestion(
      key: 'wed-wash-bedding',
      title: 'Wash bedding',
      category: 'Kitchen & Bedding',
      weekday: DateTime.wednesday,
      estimatedEffortMinutes: 10,
    );
    final task = await service.addFromSuggestion(suggestion);
    expect(task.title, 'Wash bedding');
    expect(task.recurrence, isA<StrictRecurrence>());
    expect(repo.store.values, contains(task));
  });

  test('updateTask re-stamps updatedAt and persists', () async {
    final created = await service.addTask(
      title: 'Vacuum',
      recurrence: const Recurrence.flexible(),
    );
    final later = DateTime(2026, 6, 30, 9);
    final s2 = TaskService(repository: repo, ownerId: 'u1', now: () => later);
    final updated = await s2.updateTask(
      created.copyWith(title: 'Vacuum lounge'),
    );
    expect(updated.title, 'Vacuum lounge');
    expect(updated.updatedAt, later);
    expect(repo.store[created.id]!.title, 'Vacuum lounge');
  });

  test('deleteTask removes the task', () async {
    final created = await service.addTask(
      title: 'Bins',
      recurrence: const Recurrence.flexible(),
    );
    await service.deleteTask(created.id);
    expect(repo.store, isEmpty);
  });
}
