import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/application/tasks_providers.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/domain/task.dart';
import '../data/household_repository.dart';
import '../domain/household.dart';

/// Streams the owner's household definition (empty if not signed in).
final householdProvider = StreamProvider<Household>((ref) {
  final uid = ref.watch(currentOwnerIdProvider);
  if (uid == null) return Stream.value(Household.empty);
  return ref.watch(householdRepositoryProvider).watch(uid);
});

/// Controller for household CRUD — null when there is no signed-in owner.
class HouseholdController {
  HouseholdController({
    required this.repository,
    required this.taskRepository,
    required this.ownerId,
    required this.idGen,
    required this.now,
  });

  final HouseholdRepository repository;
  final TaskRepository taskRepository;
  final String ownerId;
  final String Function() idGen;
  final DateTime Function() now;

  Future<void> addMember(Household current, String name) => repository.save(
    ownerId,
    current.withMember(HouseholdMember(id: idGen(), name: name.trim())),
  );

  /// Remove [id] from the household AND clear it from any task it was assigned
  /// to, so a removed member never leaves tasks pointing at a stale id (which
  /// would silently fold into "anyone" and never re-associate if re-added).
  /// Assignees are cleared first: if that partially fails the member stays, so
  /// the operation can be retried rather than orphaning assignments.
  Future<void> removeMember(
    Household current,
    String id, {
    List<Task> tasks = const [],
  }) async {
    for (final task in tasks) {
      if (task.assigneeId == id) {
        await taskRepository.upsert(
          task.copyWith(assigneeId: null, updatedAt: now()),
        );
      }
    }
    await repository.save(ownerId, current.withoutMember(id));
  }

  Future<void> rename(Household current, String name) =>
      repository.save(ownerId, current.copyWith(name: name.trim()));
}

/// Provides a [HouseholdController], or null when there's no signed-in owner.
final householdControllerProvider = Provider<HouseholdController?>((ref) {
  final uid = ref.watch(currentOwnerIdProvider);
  if (uid == null) return null;
  final clock = ref.watch(clockProvider);
  return HouseholdController(
    repository: ref.watch(householdRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
    ownerId: uid,
    idGen: () => 'm_${clock().microsecondsSinceEpoch}',
    now: clock,
  );
});
