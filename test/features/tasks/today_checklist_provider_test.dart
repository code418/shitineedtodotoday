import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Monday 2026-06-29 — matches the strict weekday task below.
  final monday = DateTime(2026, 6, 29);

  Task strictMondayTask() => Task(
    id: 't1',
    ownerId: 'u1',
    title: 'Vacuum',
    recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
    createdAt: monday,
    updatedAt: monday,
  );

  group('todayChecklistProvider — load-race guard', () {
    test(
      'returns empty while occurrences stream has not yet emitted',
      () async {
        // occurrencesProvider is still in AsyncLoading — simulate by not
        // providing a value override (leave it at AsyncLoading via a never-
        // emitting stream controller injected via overrideWith).
        final neverCtrl = StreamController<List<TaskOccurrence>>();
        addTearDown(neverCtrl.close);

        final container = ProviderContainer(
          overrides: [
            // tasks has a value; occurrences is still loading.
            tasksProvider.overrideWithValue(AsyncData([strictMondayTask()])),
            occurrencesProvider.overrideWith((ref) => neverCtrl.stream),
            clockProvider.overrideWithValue(() => monday),
          ],
        );
        addTearDown(container.dispose);

        // Allow any pending microtasks to settle.
        await Future.microtask(() {});

        expect(
          container.read(todayChecklistProvider),
          isEmpty,
          reason:
              'checklist must be empty until occurrences have loaded, '
              'so done/skipped items are not regenerated as pending',
        );
      },
    );

    test('generates occurrence once both streams have emitted', () {
      final container = ProviderContainer(
        overrides: [
          // Inject settled AsyncData values directly — no repository needed.
          tasksProvider.overrideWithValue(AsyncData([strictMondayTask()])),
          occurrencesProvider.overrideWithValue(
            const AsyncData(<TaskOccurrence>[]),
          ),
          clockProvider.overrideWithValue(() => monday),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(todayChecklistProvider),
        hasLength(1),
        reason:
            'once both streams have values the scheduler generates today\'s occurrence',
      );
    });
  });
}
