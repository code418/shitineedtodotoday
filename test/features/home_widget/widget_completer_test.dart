import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/home_widget/application/widget_completer.dart';
import 'package:snitd/features/home_widget/data/home_widget_bridge.dart';
import 'package:snitd/features/home_widget/domain/widget_snapshot.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

import '../../occurrence_service_test.dart' show FakeOccurrenceRepository;
import '../../task_service_test.dart' show FakeTaskRepository;

/// Widget storage in memory; records every publish.
class FakeBridge implements HomeWidgetBridge {
  String? stored;
  final published = <String>[];

  @override
  Future<void> publish(String snapshotJson) async {
    stored = snapshotJson;
    published.add(snapshotJson);
  }

  @override
  Future<String?> read() async => stored;

  @override
  Future<bool> canPin() async => false;

  @override
  Future<void> requestPin() async {}

  @override
  Future<void> registerTapHandler(
    FutureOr<void> Function(Uri?) handler,
  ) async {}
}

final _monday = DateTime(2026, 6, 29, 9);

Task _bins({int minutes = 15}) => Task(
  id: 'bins',
  ownerId: 'u1',
  title: 'Bins out',
  recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
  estimatedEffortMinutes: minutes,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final _binsToday = TaskOccurrence(
  id: 'bins_2026-06-29',
  taskId: 'bins',
  scheduledDate: DateTime(2026, 6, 29),
);

void main() {
  late FakeBridge bridge;
  late FakeTaskRepository tasks;
  late FakeOccurrenceRepository occurrences;

  setUp(() {
    bridge = FakeBridge();
    tasks = FakeTaskRepository()..store['bins'] = _bins();
    occurrences = FakeOccurrenceRepository();
    bridge.stored = jsonEncode(
      buildWidgetSnapshot(
        checklist: [_binsToday],
        tasks: [_bins()],
        today: _monday,
        ownerId: 'u1',
        strings: AppStrings.clean,
      ).toJson(),
    );
  });

  WidgetCompleter completer({String? owner = 'u1', DateTime? now}) =>
      WidgetCompleter(
        bridge: bridge,
        ownerId: owner,
        tasks: tasks,
        occurrences: occurrences,
        now: () => now ?? _monday,
      );

  WidgetSnapshot shown() => WidgetSnapshot.fromJson(
    (jsonDecode(bridge.stored!) as Map).cast<String, dynamic>(),
  );

  test('a tick completes the chore with its estimate, flagged', () async {
    final result = await completer().tick('bins_2026-06-29');

    expect(result, WidgetTickResult.completed);
    final done = occurrences.store['bins_2026-06-29']!;
    expect(done.status, OccurrenceStatus.done);
    expect(done.actualDurationMinutes, 15);
    expect(done.durationEstimated, isTrue);
    expect(done.completedAt, _monday);
  });

  test('the widget redraws with the chore ticked straight away', () async {
    await completer().tick('bins_2026-06-29');
    expect(shown().items.single.done, isTrue);
    expect(shown().left, 0);
  });

  test('ignores a tick on yesterday\'s list', () async {
    final result = await completer(
      now: DateTime(2026, 6, 30, 7),
    ).tick('bins_2026-06-29');

    expect(result, WidgetTickResult.ignored);
    expect(occurrences.store, isEmpty);
    expect(bridge.published, isEmpty);
  });

  test('ignores a tick once signed out or signed in as someone else', () async {
    expect(
      await completer(owner: null).tick('bins_2026-06-29'),
      WidgetTickResult.ignored,
    );
    expect(
      await completer(owner: 'someone-else').tick('bins_2026-06-29'),
      WidgetTickResult.ignored,
    );
    expect(occurrences.store, isEmpty);
  });

  test('ignores a chore that isn\'t on the widget (a forged tap)', () async {
    expect(
      await completer().tick('other_2026-06-29'),
      WidgetTickResult.ignored,
    );
    expect(occurrences.store, isEmpty);
  });

  test('leaves a chore already settled in the app alone', () async {
    // Skipped in the app after the widget last synced.
    occurrences.store['bins_2026-06-29'] = _binsToday.copyWith(
      status: OccurrenceStatus.skipped,
    );

    final result = await completer().tick('bins_2026-06-29');

    expect(result, WidgetTickResult.alreadySettled);
    expect(
      occurrences.store['bins_2026-06-29']!.status,
      OccurrenceStatus.skipped,
    );
  });

  test('no stored snapshot (widget never synced) does nothing', () async {
    bridge.stored = null;
    expect(await completer().tick('bins_2026-06-29'), WidgetTickResult.ignored);
  });
}
