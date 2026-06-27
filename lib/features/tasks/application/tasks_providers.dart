import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/starter_tasks.dart';
import '../domain/scheduling/forgiving_scheduler.dart';
import '../domain/scheduling/scheduler.dart';
import '../domain/scheduling/task_occurrence.dart';
import '../domain/task_suggestion.dart';

/// The active scheduling engine. Every consumer reads it through this provider.
final schedulerProvider = Provider<Scheduler>(
  (ref) => const ForgivingScheduler(),
);

/// Today's checklist — the occurrences the user should see now.
///
/// Currently returns an empty list via [PlaceholderScheduler]. Upcoming work
/// wires this to the owner's tasks + persisted occurrences (watched from
/// Firestore) and runs them through [Scheduler.buildToday].
final todayChecklistProvider = Provider<List<TaskOccurrence>>((ref) {
  final scheduler = ref.watch(schedulerProvider);
  // TODO(upcoming): source active tasks + existing occurrences for the signed-in
  // owner and pass them here instead of the empty placeholders.
  return scheduler.buildToday(
    tasks: const [],
    today: DateTime.now(),
    existing: const [],
  );
});

/// Ready-made starter tasks (the curated cleaning plan from the planner PDF),
/// offered to new users so they can get going without a blank page.
final starterSuggestionsProvider = Provider<List<TaskSuggestion>>(
  (ref) => kStarterCleaningPlan,
);

/// The starter suggestions grouped by their themed day/category, preserving the
/// catalogue's order (Mon → Sun).
final starterSuggestionsByCategoryProvider =
    Provider<Map<String, List<TaskSuggestion>>>((ref) {
      final grouped = <String, List<TaskSuggestion>>{};
      for (final suggestion in ref.watch(starterSuggestionsProvider)) {
        grouped.putIfAbsent(suggestion.category, () => []).add(suggestion);
      }
      return grouped;
    });
