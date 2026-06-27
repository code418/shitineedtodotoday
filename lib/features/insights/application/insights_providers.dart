import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/application/tasks_providers.dart';
import '../../tasks/domain/scheduling/task_occurrence.dart';
import '../../tasks/domain/task.dart';
import '../domain/insights.dart';

/// Memoised insights summary — recomputes only when occurrences, tasks or the
/// clock change. Riverpod caches per [InsightsPeriod], so switching period tabs
/// back is a cache hit rather than a fresh computation.
final insightsSummaryProvider =
    Provider.family<InsightsSummary, InsightsPeriod>((ref, period) {
      final occurrences =
          ref.watch(occurrencesProvider).value ?? const <TaskOccurrence>[];
      final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
      final now = ref.watch(clockProvider)();
      return computeInsights(
        occurrences: occurrences,
        tasks: tasks,
        now: now,
        period: period,
      );
    });
