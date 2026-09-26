import 'dart:convert';

import '../../tasks/application/occurrence_service.dart';
import '../../tasks/data/occurrence_repository.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/domain/scheduling/forgiving_scheduler.dart';
import '../data/home_widget_bridge.dart';
import '../domain/widget_snapshot.dart';

/// What happened to a tick on the home-screen widget.
enum WidgetTickResult {
  /// Completed, with the task's estimate logged as the (estimated) time.
  completed,

  /// Nothing done: the widget's list is from an earlier day, or for another
  /// account (signed out / switched since), or the chore isn't on it.
  ignored,

  /// Nothing done: it was already done or skipped (e.g. in the app).
  alreadySettled,
}

/// Handles a tick on the home-screen widget, in a background isolate with no
/// UI. Per the product owner, a widget tick completes the chore with its
/// estimate as the time — flagged as estimated so the app offers to correct
/// it — through the same [OccurrenceService.complete] the app uses.
class WidgetCompleter {
  WidgetCompleter({
    required this.bridge,
    required this.ownerId,
    required this.tasks,
    required this.occurrences,
    required this.now,
  });

  final HomeWidgetBridge bridge;

  /// The signed-in user now (null when signed out).
  final String? ownerId;
  final TaskRepository tasks;
  final OccurrenceRepository occurrences;
  final DateTime Function() now;

  Future<WidgetTickResult> tick(String occurrenceId) async {
    final raw = await bridge.read();
    if (raw == null || ownerId == null) return WidgetTickResult.ignored;
    final snapshot = WidgetSnapshot.fromJson(
      (jsonDecode(raw) as Map).cast<String, dynamic>(),
    );
    // Only today's list, and only the account that published it.
    if (snapshot.ownerId != ownerId || snapshot.day != widgetDay(now())) {
      return WidgetTickResult.ignored;
    }
    final item = snapshot.items.where((i) => i.id == occurrenceId).firstOrNull;
    if (item == null || item.done) return WidgetTickResult.ignored;

    // Redraw straight away: the tap should feel instant even though the write
    // below waits for the server.
    await bridge.publish(jsonEncode(snapshot.markDone(occurrenceId).toJson()));

    final owner = ownerId!;
    final task = (await tasks.watchTasks(owner).first)
        .where((t) => t.id == item.occurrence.taskId)
        .firstOrNull;
    final history = [
      for (final o in await occurrences.watchOccurrences(owner).first)
        if (o.taskId == item.occurrence.taskId) o,
    ];
    // The persisted state wins over the widget's copy: if it was done or
    // skipped in the app meanwhile, leave it be.
    final current =
        history.where((o) => o.id == occurrenceId).firstOrNull ??
        item.occurrence;
    if (task == null || !current.isOpen) {
      return WidgetTickResult.alreadySettled;
    }

    await OccurrenceService(
      occurrences: occurrences,
      tasks: tasks,
      scheduler: const ForgivingScheduler(),
      ownerId: owner,
      now: now,
    ).complete(
      occurrence: current,
      task: task,
      actualMinutes: task.estimatedEffortMinutes,
      history: history,
      estimated: true,
    );
    return WidgetTickResult.completed;
  }
}
