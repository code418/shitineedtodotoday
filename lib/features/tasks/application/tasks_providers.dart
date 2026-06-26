import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/scheduling/scheduler.dart';
import '../domain/scheduling/task_occurrence.dart';

/// The active scheduling engine.
///
/// Swap [PlaceholderScheduler] for the real engine once it lands — every
/// consumer reads it through this provider, so nothing else needs to change.
final schedulerProvider = Provider<Scheduler>(
  (ref) => const PlaceholderScheduler(),
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
