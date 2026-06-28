import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../domain/scheduling/task_occurrence.dart';

/// Reads and writes [TaskOccurrence]s — the concrete daily-checklist items
/// generated from a task's recurrence and mutated as the user ticks, skips or
/// reschedules them.
abstract interface class OccurrenceRepository {
  /// Streams the owner's occurrences. The scheduler dedupes against these so we
  /// never regenerate one that's already persisted (e.g. a completed item).
  Stream<List<TaskOccurrence>> watchOccurrences(String ownerId);

  /// Creates or updates an occurrence (keyed by its deterministic id).
  Future<void> upsert(String ownerId, TaskOccurrence occurrence);

  Future<void> delete(String ownerId, String occurrenceId);

  /// Removes every occurrence belonging to [taskId] — used to cascade when a
  /// task is deleted so no orphaned occurrences are left behind.
  Future<void> deleteForTask(String ownerId, String taskId);
}

/// Firestore-backed [OccurrenceRepository].
///
/// Layout: `users/{ownerId}/occurrences/{occurrenceId}` — owner-scoped by
/// `firestore.rules`. `DateTime`s are stored as ISO-8601 strings (via
/// `toJson`), which sort correctly for `orderBy`.
class FirestoreOccurrenceRepository implements OccurrenceRepository {
  FirestoreOccurrenceRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _ref(String ownerId) =>
      _firestore.collection('users').doc(ownerId).collection('occurrences');

  @override
  Stream<List<TaskOccurrence>> watchOccurrences(String ownerId) {
    return _ref(ownerId)
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TaskOccurrence.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  @override
  Future<void> upsert(String ownerId, TaskOccurrence occurrence) =>
      _ref(ownerId).doc(occurrence.id).set(occurrence.toJson());

  @override
  Future<void> delete(String ownerId, String occurrenceId) =>
      _ref(ownerId).doc(occurrenceId).delete();

  @override
  Future<void> deleteForTask(String ownerId, String taskId) async {
    final matching = await _ref(
      ownerId,
    ).where('taskId', isEqualTo: taskId).get();
    final docs = matching.docs;
    if (docs.isEmpty) return;
    // A long-lived daily task can accrue hundreds of occurrences; Firestore
    // rejects a batch with more than 500 writes, so commit in chunks.
    for (var i = 0; i < docs.length; i += _batchLimit) {
      final batch = _firestore.batch();
      for (final doc in docs.skip(i).take(_batchLimit)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// Firestore's maximum number of writes in a single batched commit.
  static const _batchLimit = 500;
}

final occurrenceRepositoryProvider = Provider<OccurrenceRepository>(
  (ref) => FirestoreOccurrenceRepository(ref.watch(firestoreProvider)),
);
