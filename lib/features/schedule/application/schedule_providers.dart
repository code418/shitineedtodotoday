import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/application/tasks_providers.dart';
import '../../tasks/domain/scheduling/task_occurrence.dart';
import '../../tasks/domain/task.dart';
import '../domain/agenda.dart';

/// The current week's agenda: 7 [AgendaDay]s from Monday to Sunday.
final weekAgendaProvider = Provider<List<AgendaDay>>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  final existing =
      ref.watch(occurrencesProvider).value ?? const <TaskOccurrence>[];
  final now = ref.watch(clockProvider)();
  return buildWeekAgenda(
    scheduler: ref.watch(schedulerProvider),
    tasks: tasks,
    existing: existing,
    weekStart: weekStartFor(now),
  );
});
