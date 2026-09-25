import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/auth/domain/guest_merge.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

Task _task(
  String id,
  String owner,
  String title, {
  Recurrence recurrence = const Recurrence.strict(weekdays: [DateTime.monday]),
  String? assigneeId,
}) => Task(
  id: id,
  ownerId: owner,
  title: title,
  recurrence: recurrence,
  assigneeId: assigneeId,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

TaskOccurrence _occ(String taskId) => TaskOccurrence(
  id: '${taskId}_2026-06-29',
  taskId: taskId,
  scheduledDate: DateTime(2026, 6, 29),
  status: OccurrenceStatus.done,
  completedAt: DateTime(2026, 6, 29, 9),
  actualDurationMinutes: 10,
);

void main() {
  test('re-owns guest tasks, keeps their history, clears assignees', () {
    final plan = planGuestMerge(
      guestTasks: [_task('g1', 'guest', 'Water plants', assigneeId: 'm-1')],
      guestOccurrences: [_occ('g1')],
      accountTasks: [_task('a1', 'acct', 'Bins')],
      accountOwnerId: 'acct',
    );

    expect(plan.tasks.single.id, 'g1');
    expect(plan.tasks.single.ownerId, 'acct');
    // The guest's household members don't exist in the account.
    expect(plan.tasks.single.assigneeId, isNull);
    expect(plan.occurrences.map((o) => o.id), ['g1_2026-06-29']);
    expect(plan.skippedDuplicates, 0);
  });

  test('skips a chore the account already has, with its history', () {
    // A returning user onboarded on a new device, then signed in: the starter
    // chores exist on both sides and must not appear twice.
    final plan = planGuestMerge(
      guestTasks: [
        _task('g1', 'guest', '  wipe the COUNTERS '),
        _task('g2', 'guest', 'Descale kettle'),
      ],
      guestOccurrences: [_occ('g1'), _occ('g2')],
      accountTasks: [_task('a1', 'acct', 'Wipe the counters')],
      accountOwnerId: 'acct',
    );

    expect(plan.tasks.map((t) => t.id), ['g2']);
    expect(plan.occurrences.map((o) => o.taskId), ['g2']);
    expect(plan.skippedDuplicates, 1);
  });

  test('the same title on a different schedule is a different chore', () {
    final plan = planGuestMerge(
      guestTasks: [
        _task(
          'g1',
          'guest',
          'Bins',
          recurrence: const Recurrence.strict(weekdays: [DateTime.thursday]),
        ),
      ],
      guestOccurrences: const [],
      accountTasks: [_task('a1', 'acct', 'Bins')],
      accountOwnerId: 'acct',
    );

    expect(plan.tasks.map((t) => t.id), ['g1']);
    expect(plan.skippedDuplicates, 0);
  });

  test('a guest with nothing yields an empty plan', () {
    final plan = planGuestMerge(
      guestTasks: const [],
      guestOccurrences: const [],
      accountTasks: [_task('a1', 'acct', 'Bins')],
      accountOwnerId: 'acct',
    );
    expect(plan.isEmpty, isTrue);
    expect(plan.occurrences, isEmpty);
  });
}
