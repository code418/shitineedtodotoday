import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/features/home_widget/application/widget_sync.dart';
import 'package:snitd/features/home_widget/data/home_widget_bridge.dart';
import 'package:snitd/features/home_widget/domain/widget_snapshot.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

import 'widget_completer_test.dart' show FakeBridge;

final _bins = Task(
  id: 'bins',
  ownerId: 'u1',
  title: 'Bins out',
  recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late FakeBridge bridge;
  late StreamController<List<Task>> tasks;
  late StreamController<List<TaskOccurrence>> occurrences;
  late ProviderContainer container;

  Future<ProviderContainer> start({String? owner = 'u1'}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentOwnerIdProvider.overrideWithValue(owner),
        tasksProvider.overrideWith((ref) => tasks.stream),
        occurrencesProvider.overrideWith((ref) => occurrences.stream),
        clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
        homeWidgetBridgeProvider.overrideWithValue(bridge),
      ],
    );
    c.listen(widgetSyncProvider, (_, _) {});
    return c;
  }

  setUp(() {
    bridge = FakeBridge();
    tasks = StreamController<List<Task>>();
    occurrences = StreamController<List<TaskOccurrence>>();
  });

  tearDown(() {
    container.dispose();
    tasks.close();
    occurrences.close();
  });

  WidgetSnapshot last() => WidgetSnapshot.fromJson(
    (jsonDecode(bridge.published.last) as Map).cast<String, dynamic>(),
  );

  test('waits for real data, then publishes today\'s list', () async {
    container = await start();
    await pumpEventQueue();
    // Still loading: publishing now would flash "nothing today".
    expect(bridge.published, isEmpty);

    tasks.add([_bins]);
    occurrences.add(const []);
    await pumpEventQueue();

    expect(bridge.published, hasLength(1));
    expect(last().items.single.title, 'Bins out');
    expect(last().left, 1);
  });

  test('republishes when the list changes, but never a repeat', () async {
    container = await start();
    tasks.add([_bins]);
    occurrences.add(const []);
    await pumpEventQueue();

    // Ticked in the app → the widget follows.
    occurrences.add([
      TaskOccurrence(
        id: 'bins_2026-06-29',
        taskId: 'bins',
        scheduledDate: DateTime(2026, 6, 29),
        status: OccurrenceStatus.done,
        actualDurationMinutes: 10,
      ),
    ]);
    await pumpEventQueue();
    expect(bridge.published, hasLength(2));
    expect(last().left, 0);

    // The same tasks again: nothing new to draw.
    tasks.add([_bins]);
    await pumpEventQueue();
    expect(bridge.published, hasLength(2));
  });

  test('with no one signed in, the widget is left alone', () async {
    container = await start(owner: null);
    tasks.add([_bins]);
    occurrences.add(const []);
    await pumpEventQueue();
    expect(bridge.published, isEmpty);
  });
}
