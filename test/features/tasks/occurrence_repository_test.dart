import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';

/// Build one `(id, data)` occurrence doc as it arrives from Firestore (the id is
/// injected by decodeDocs, so it's not in the data map).
OccurrenceDoc doc(
  String id,
  String scheduledDate, {
  String status = 'pending',
  String taskId = 't',
}) =>
    (id, {'taskId': taskId, 'scheduledDate': scheduledDate, 'status': status});

String iso(String day) => '${day}T00:00:00.000';

void main() {
  group('occurrenceWindowFloor', () {
    test('is `days` back at local midnight, same format as stored dates', () {
      final now = DateTime(2026, 7, 24, 15, 30);
      expect(
        occurrenceWindowFloor(now, days: 400),
        DateTime(2026, 7, 24 - 400).toIso8601String(),
      );
      // Must match how scheduledDate is actually persisted, or the string `>=`
      // bound would compare against a different shape.
      final stored = TaskOccurrence(
        id: 'x',
        taskId: 't',
        scheduledDate: DateTime(2025, 1, 1),
      ).toJson()['scheduledDate'];
      expect(stored, '2025-01-01T00:00:00.000');
      expect(occurrenceWindowFloor(now).endsWith('Z'), isFalse);
    });

    test('the default window covers the insights year view with margin', () {
      // Insights "year" starts on the 1st of the month 11 months ago. The floor
      // must sit before that, or the year view would be truncated.
      final now = DateTime(2026, 7, 24);
      final yearWindowStart = DateTime(2025, 8); // ~11 months back
      expect(
        DateTime.parse(occurrenceWindowFloor(now)).isBefore(yearWindowStart),
        isTrue,
      );
    });
  });

  group('combineOccurrenceStreams', () {
    late StreamController<List<OccurrenceDoc>> open;
    late StreamController<List<OccurrenceDoc>> recent;

    setUp(() {
      open = StreamController<List<OccurrenceDoc>>();
      recent = StreamController<List<OccurrenceDoc>>();
    });

    tearDown(() async {
      await open.close();
      await recent.close();
    });

    test('waits for BOTH streams before the first emission', () async {
      final emissions = <List<TaskOccurrence>>[];
      final sub = combineOccurrenceStreams(
        open.stream,
        recent.stream,
      ).listen(emissions.add);

      open.add([doc('a', iso('2026-07-20'))]);
      await pumpEventQueue();
      expect(emissions, isEmpty, reason: 'only the open side has emitted');

      recent.add([doc('b', iso('2026-07-24'))]);
      await pumpEventQueue();
      expect(emissions, hasLength(1));
      // Newest first, preserving the old single-query ordering.
      expect(emissions.single.map((o) => o.id), ['b', 'a']);

      await sub.cancel();
    });

    test(
      'unions by id — an open occurrence inside the window is not doubled',
      () async {
        final emissions = <List<TaskOccurrence>>[];
        final sub = combineOccurrenceStreams(
          open.stream,
          recent.stream,
        ).listen(emissions.add);

        // 'a' is open AND inside the recent window, so it arrives on both streams.
        open.add([doc('a', iso('2026-07-24'))]);
        recent.add([doc('a', iso('2026-07-24')), doc('b', iso('2026-07-23'))]);
        await pumpEventQueue();

        expect(emissions.last.map((o) => o.id), ['a', 'b']);
        await sub.cancel();
      },
    );

    test('re-emits when either side updates', () async {
      final emissions = <List<TaskOccurrence>>[];
      final sub = combineOccurrenceStreams(
        open.stream,
        recent.stream,
      ).listen(emissions.add);

      open.add([doc('a', iso('2026-07-20'))]);
      recent.add([doc('b', iso('2026-07-24'))]);
      await pumpEventQueue();
      expect(emissions, hasLength(1));

      recent.add([doc('b', iso('2026-07-24')), doc('c', iso('2026-07-25'))]);
      await pumpEventQueue();
      expect(emissions, hasLength(2));
      expect(emissions.last.map((o) => o.id), ['c', 'b', 'a']);

      await sub.cancel();
    });

    test('forwards an error from either query', () async {
      final errors = <Object>[];
      final sub = combineOccurrenceStreams(
        open.stream,
        recent.stream,
      ).listen((_) {}, onError: errors.add);

      recent.addError(StateError('permission denied'));
      await pumpEventQueue();
      expect(errors, hasLength(1));

      await sub.cancel();
    });

    test(
      'cancelling the merged stream stops listening to both upstreams',
      () async {
        final sub = combineOccurrenceStreams(
          open.stream,
          recent.stream,
        ).listen((_) {});
        // Subscriptions are wired on listen.
        await pumpEventQueue();
        expect(open.hasListener, isTrue);
        expect(recent.hasListener, isTrue);

        await sub.cancel();
        expect(open.hasListener, isFalse);
        expect(recent.hasListener, isFalse);
      },
    );
  });
}
