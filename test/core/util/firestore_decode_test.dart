import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/util/firestore_decode.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

void main() {
  group('decodeDocs', () {
    test('injects the id and decodes valid docs', () {
      final docs = [
        (
          't1',
          {
            'ownerId': 'u1',
            'title': 'Vacuum',
            'recurrence': const Recurrence.strict(weekdays: [1]).toJson(),
            'createdAt': '2026-06-01T00:00:00.000',
            'updatedAt': '2026-06-01T00:00:00.000',
          },
        ),
      ];

      final tasks = decodeDocs(docs, Task.fromJson, label: 'task');

      expect(tasks, hasLength(1));
      expect(tasks.single.id, 't1');
      expect(tasks.single.title, 'Vacuum');
    });

    test(
      'skips a malformed doc instead of throwing, keeping the good ones',
      () {
        Map<String, dynamic> valid(String title) => {
          'ownerId': 'u1',
          'title': title,
          'recurrence': const Recurrence.strict(weekdays: [1]).toJson(),
          'createdAt': '2026-06-01T00:00:00.000',
          'updatedAt': '2026-06-01T00:00:00.000',
        };

        final docs = <(String, Map<String, dynamic>)>[
          ('good1', valid('A')),
          // Missing required fields (title/recurrence/dates) → fromJson throws.
          ('bad', {'ownerId': 'u1'}),
          ('good2', valid('B')),
        ];

        final tasks = decodeDocs(docs, Task.fromJson, label: 'task');

        // The one bad doc is dropped; the two good ones still load.
        expect(tasks.map((t) => t.id), ['good1', 'good2']);
      },
    );

    test('returns an empty list for no docs', () {
      expect(
        decodeDocs(
          const <(String, Map<String, dynamic>)>[],
          Task.fromJson,
          label: 'task',
        ),
        isEmpty,
      );
    });
  });
}
