import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/home_widget/domain/widget_snapshot.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

Task _task(String id, String title, {int minutes = 10}) => Task(
  id: id,
  ownerId: 'u1',
  title: title,
  recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
  estimatedEffortMinutes: minutes,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

TaskOccurrence _occ(String taskId, {bool done = false}) => TaskOccurrence(
  id: '${taskId}_2026-06-29',
  taskId: taskId,
  scheduledDate: DateTime(2026, 6, 29),
  status: done ? OccurrenceStatus.done : OccurrenceStatus.pending,
);

void main() {
  final today = DateTime(2026, 6, 29, 9);

  WidgetSnapshot build(
    List<TaskOccurrence> checklist, {
    List<Task>? tasks,
    AppStrings strings = AppStrings.clean,
    int maxRows = kWidgetMaxRows,
  }) => buildWidgetSnapshot(
    checklist: checklist,
    tasks: tasks ?? [for (final o in checklist) _task(o.taskId, o.taskId)],
    today: today,
    ownerId: 'u1',
    strings: strings,
    maxRows: maxRows,
  );

  test('lists open chores before done ones, with the counts', () {
    final s = build([_occ('a', done: true), _occ('b'), _occ('c')]);

    expect(s.items.map((i) => i.id), [
      'b_2026-06-29',
      'c_2026-06-29',
      'a_2026-06-29',
    ]);
    expect(s.items.map((i) => i.done), [false, false, true]);
    expect(s.left, 2);
    expect(s.total, 3);
    expect(s.day, '2026-06-29');
    expect(s.ownerId, 'u1');
  });

  test('caps the rows and counts the rest as hidden', () {
    final s = build([for (final id in 'abcdefg'.split('')) _occ(id)]);
    expect(s.items, hasLength(kWidgetMaxRows));
    expect(s.total, 7);
    expect(s.hidden, 2);
  });

  test('carries the chore title, estimate and the full occurrence', () {
    final occ = _occ('bins');
    final s = build([occ], tasks: [_task('bins', 'Bins out', minutes: 5)]);
    expect(s.items.single.title, 'Bins out');
    expect(s.items.single.minutes, 5);
    // Most of today is generated on the fly, not persisted: a background tick
    // needs the whole record to write it.
    expect(s.items.single.occurrence, occ);
  });

  test('skips an occurrence whose task has gone', () {
    final s = build([_occ('gone'), _occ('b')], tasks: [_task('b', 'B')]);
    expect(s.items.map((i) => i.title), ['B']);
    expect(s.total, 1);
  });

  test('labels follow the chosen string set', () {
    final clean = build([_occ('a')]);
    final profane = build([_occ('a')], strings: AppStrings.profane);
    expect(clean.labels['title'], AppStrings.clean.todayTitle);
    expect(profane.labels['title'], AppStrings.profane.todayTitle);
    expect(clean.labels['progress'], '{left} of {total} left');
    expect(clean.labels['stale'], AppStrings.clean.widgetStale);
  });

  test('markDone ticks one chore and counts it', () {
    final s = build([_occ('a'), _occ('b')]).markDone('a_2026-06-29');
    expect(s.items.firstWhere((i) => i.id == 'a_2026-06-29').done, isTrue);
    expect(s.left, 1);
    expect(s.total, 2);
    // Ticking a done or unknown chore changes nothing.
    expect(s.markDone('a_2026-06-29').left, 1);
    expect(s.markDone('nope').left, 1);
  });

  test('round-trips through JSON, as stored for the native widget', () {
    final s = build([_occ('a'), _occ('b', done: true)]);
    final back = WidgetSnapshot.fromJson(
      (jsonDecode(jsonEncode(s.toJson())) as Map).cast<String, dynamic>(),
    );
    expect(back.toJson(), s.toJson());
  });
}
