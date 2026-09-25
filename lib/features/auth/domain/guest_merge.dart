import '../../tasks/domain/scheduling/task_occurrence.dart';
import '../../tasks/domain/task.dart';

/// What to copy from a guest (anonymous) account into the account being
/// signed in to.
class GuestMergePlan {
  const GuestMergePlan({
    required this.tasks,
    required this.occurrences,
    required this.skippedDuplicates,
  });

  /// Guest tasks re-owned by the account, ready to write.
  final List<Task> tasks;

  /// The persisted history of [tasks] (occurrence docs are owner-scoped by
  /// path, so they carry over unchanged).
  final List<TaskOccurrence> occurrences;

  /// Guest tasks left out because the account already has the same chore.
  final int skippedDuplicates;

  bool get isEmpty => tasks.isEmpty;
}

/// Plans merging a guest's [guestTasks] (and their [guestOccurrences]) into an
/// account that already holds [accountTasks], owned by [accountOwnerId].
///
/// A guest task the account already has — same title (ignoring case and outer
/// spaces) and same recurrence — is skipped along with its history: a returning
/// user who onboarded on a new device before signing in would otherwise get
/// every starter chore twice. Assignees are cleared, since they point at the
/// guest's household members, which don't exist in the account.
GuestMergePlan planGuestMerge({
  required List<Task> guestTasks,
  required List<TaskOccurrence> guestOccurrences,
  required List<Task> accountTasks,
  required String accountOwnerId,
}) {
  (String, Object) key(Task t) => (t.title.trim().toLowerCase(), t.recurrence);
  final accountKeys = {for (final t in accountTasks) key(t)};
  final accountIds = {for (final t in accountTasks) t.id};

  final kept = [
    for (final t in guestTasks)
      if (!accountKeys.contains(key(t)) && !accountIds.contains(t.id))
        t.copyWith(ownerId: accountOwnerId, assigneeId: null),
  ];
  final keptIds = {for (final t in kept) t.id};

  return GuestMergePlan(
    tasks: kept,
    occurrences: [
      for (final o in guestOccurrences)
        if (keptIds.contains(o.taskId)) o,
    ],
    skippedDuplicates: guestTasks.length - kept.length,
  );
}
