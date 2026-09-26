import '../../../core/strings/app_strings.dart';
import '../../tasks/domain/scheduling/forgiving_scheduler.dart' show dateOnly;
import '../../tasks/domain/scheduling/task_occurrence.dart';
import '../../tasks/domain/task.dart';

/// How many chores the Android widget has rows for.
const kWidgetMaxRows = 5;

/// One chore row on the home-screen widget.
class WidgetItem {
  const WidgetItem({
    required this.occurrence,
    required this.title,
    required this.minutes,
    required this.done,
  });

  /// The occurrence as the checklist had it — the full record, since most of
  /// today's chores are materialised on the fly and not persisted yet, so a
  /// background tick has to be able to write the whole thing.
  final TaskOccurrence occurrence;
  final String title;
  final int minutes;
  final bool done;

  String get id => occurrence.id;

  WidgetItem copyWith({bool? done}) => WidgetItem(
    occurrence: occurrence,
    title: title,
    minutes: minutes,
    done: done ?? this.done,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'minutes': minutes,
    'done': done,
    'occurrence': occurrence.toJson(),
  };

  factory WidgetItem.fromJson(Map<String, dynamic> json) => WidgetItem(
    occurrence: TaskOccurrence.fromJson(
      (json['occurrence'] as Map).cast<String, dynamic>(),
    ),
    title: json['title'] as String,
    minutes: json['minutes'] as int,
    done: json['done'] as bool,
  );
}

/// Everything the Android home-screen widget draws, rendered ahead of time by
/// the app so the native widget needs no Flutter: today's chores (open ones
/// first), the counts, and the labels in the user's chosen string set.
///
/// It's also what a background tick trusts: [day] and [ownerId] let it refuse
/// to act on yesterday's list or on another account's.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.day,
    required this.ownerId,
    required this.items,
    required this.left,
    required this.total,
    required this.labels,
  });

  /// The local day this list is for, `yyyy-MM-dd`.
  final String day;
  final String ownerId;

  /// Up to [kWidgetMaxRows] chores: open ones first, then done.
  final List<WidgetItem> items;

  /// Open chores today, and all of today's (non-skipped) chores — including
  /// any beyond the rows shown.
  final int left;
  final int total;

  /// Pre-rendered copy; `progress` and `more` are templates the widget fills
  /// (`{left}`, `{total}`, `{n}`), so a tick can update counts without the app.
  final Map<String, String> labels;

  /// Chores that didn't fit in the rows.
  int get hidden => total - items.length;

  /// This snapshot with [occurrenceId] ticked off, as the widget should look
  /// straight after a tap (before the write reaches Firestore).
  WidgetSnapshot markDone(String occurrenceId) {
    final wasOpen = items.any((i) => i.id == occurrenceId && !i.done);
    if (!wasOpen) return this;
    return WidgetSnapshot(
      day: day,
      ownerId: ownerId,
      items: [
        for (final i in items)
          i.id == occurrenceId ? i.copyWith(done: true) : i,
      ],
      left: left - 1,
      total: total,
      labels: labels,
    );
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'ownerId': ownerId,
    'items': [for (final i in items) i.toJson()],
    'left': left,
    'total': total,
    'labels': labels,
  };

  factory WidgetSnapshot.fromJson(Map<String, dynamic> json) => WidgetSnapshot(
    day: json['day'] as String,
    ownerId: json['ownerId'] as String,
    items: [
      for (final i in json['items'] as List)
        WidgetItem.fromJson((i as Map).cast<String, dynamic>()),
    ],
    left: json['left'] as int,
    total: json['total'] as int,
    labels: (json['labels'] as Map).cast<String, String>(),
  );
}

/// `yyyy-MM-dd` for [date]'s local calendar day.
String widgetDay(DateTime date) {
  final d = dateOnly(date);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}

/// Builds the widget's view of [checklist] — the same list Today shows — for
/// [ownerId] on [today], labelled in [strings].
WidgetSnapshot buildWidgetSnapshot({
  required List<TaskOccurrence> checklist,
  required List<Task> tasks,
  required DateTime today,
  required String ownerId,
  required AppStrings strings,
  int maxRows = kWidgetMaxRows,
}) {
  final taskById = {for (final t in tasks) t.id: t};
  WidgetItem? item(TaskOccurrence o) {
    final task = taskById[o.taskId];
    if (task == null) return null;
    return WidgetItem(
      occurrence: o,
      title: task.title,
      minutes: task.estimatedEffortMinutes,
      done: o.status == OccurrenceStatus.done,
    );
  }

  final all = [for (final o in checklist) ?item(o)];
  final ordered = [...all.where((i) => !i.done), ...all.where((i) => i.done)];

  return WidgetSnapshot(
    day: widgetDay(today),
    ownerId: ownerId,
    items: ordered.take(maxRows).toList(),
    left: all.where((i) => !i.done).length,
    total: all.length,
    labels: {
      'title': strings.todayTitle,
      'progress': strings.focusProgress,
      'allDone': strings.focusAllDoneTitle,
      'empty': strings.emptyTitle,
      'stale': strings.widgetStale,
      'more': strings.widgetMore,
      'tick': strings.widgetTick,
      'done': strings.chartDoneSuffix,
    },
  );
}
