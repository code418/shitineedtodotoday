import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../core/util/firestore_decode.dart';
import '../application/tasks_providers.dart';
import '../domain/scheduling/task_occurrence.dart';

/// Reads and writes [TaskOccurrence]s — the concrete daily-checklist items
/// generated from a task's recurrence and mutated as the user ticks, skips or
/// reschedules them.
abstract interface class OccurrenceRepository {
  /// Streams the occurrences the app needs live: every still-open occurrence
  /// (any age — the forgiving carry-forward can resurface a months-old miss),
  /// plus everything within a recent window (for insights + task history).
  /// Older *settled* occurrences are left on the server rather than streamed and
  /// held in memory forever — see [occurrenceWindowDays].
  Stream<List<TaskOccurrence>> watchOccurrences(String ownerId);

  /// Creates or updates an occurrence (keyed by its deterministic id).
  Future<void> upsert(String ownerId, TaskOccurrence occurrence);

  Future<void> delete(String ownerId, String occurrenceId);

  /// Removes every occurrence belonging to [taskId] — used to cascade when a
  /// task is deleted so no orphaned occurrences are left behind.
  Future<void> deleteForTask(String ownerId, String taskId);
}

/// How many days of history [OccurrenceRepository.watchOccurrences] streams.
///
/// Must comfortably exceed the furthest back any consumer of the recent window
/// looks: the insights "year" view starts on the 1st of the month 11 months ago
/// (up to ~365 days). 400 days keeps that fully covered with margin. Beyond this
/// window only *open* work is still streamed (by status, any age); older
/// done/skipped occurrences stay on the server, which is what stops a long-lived
/// account re-reading thousands of docs on every cold start.
const int occurrenceWindowDays = 400;

/// One occurrence document as `(id, data)`, before decoding.
typedef OccurrenceDoc = (String, Map<String, dynamic>);

/// The inclusive lower bound for the recent-window query, as the ISO-8601 string
/// `scheduledDate` is stored in. [now] is stripped to its local calendar day,
/// [days] back. ISO-8601 sorts lexicographically in chronological order, so a
/// string `>=` bound is exact.
String occurrenceWindowFloor(DateTime now, {int days = occurrenceWindowDays}) {
  final floor = DateTime(now.year, now.month, now.day - days);
  return floor.toIso8601String();
}

/// Merges the two occurrence queries into a single decoded, de-duplicated,
/// newest-first list, waiting until BOTH have delivered their first snapshot so
/// no consumer ever sees a half-built list (missing all the open work, or all
/// the recent work). Re-emits whenever either side updates; forwards either
/// side's error; cancels both when the listener goes away.
///
/// Kept free of Firestore types so the merge/dedup/ordering — the fiddly part —
/// is unit-testable with plain streams.
Stream<List<TaskOccurrence>> combineOccurrenceStreams(
  Stream<List<OccurrenceDoc>> open,
  Stream<List<OccurrenceDoc>> recent,
) {
  List<OccurrenceDoc>? latestOpen;
  List<OccurrenceDoc>? latestRecent;
  var openSeen = false;
  var recentSeen = false;
  StreamSubscription<List<OccurrenceDoc>>? openSub;
  StreamSubscription<List<OccurrenceDoc>>? recentSub;

  final controller = StreamController<List<TaskOccurrence>>();

  void emit() {
    // Hold the first emission until both sides have delivered once; after that
    // an update to either re-emits with the other's latest.
    if (!openSeen || !recentSeen) return;
    controller.add(_mergeDecode(latestOpen!, latestRecent!));
  }

  controller.onListen = () {
    openSub = open.listen((docs) {
      latestOpen = docs;
      openSeen = true;
      emit();
    }, onError: controller.addError);
    recentSub = recent.listen((docs) {
      latestRecent = docs;
      recentSeen = true;
      emit();
    }, onError: controller.addError);
  };
  controller.onCancel = () async {
    await openSub?.cancel();
    await recentSub?.cancel();
  };

  return controller.stream;
}

/// Union by document id (an open occurrence inside the recent window arrives on
/// both streams), decoded defensively and sorted newest-first to preserve the
/// old single-query ordering.
List<TaskOccurrence> _mergeDecode(
  List<OccurrenceDoc> open,
  List<OccurrenceDoc> recent,
) {
  final byId = <String, Map<String, dynamic>>{};
  for (final (id, data) in open) {
    byId[id] = data;
  }
  for (final (id, data) in recent) {
    byId[id] = data;
  }
  final decoded = decodeDocs(
    [for (final e in byId.entries) (e.key, e.value)],
    TaskOccurrence.fromJson,
    label: 'occurrence',
  );
  decoded.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
  return decoded;
}

/// Firestore-backed [OccurrenceRepository].
///
/// Layout: `users/{ownerId}/occurrences/{occurrenceId}` — owner-scoped by
/// `firestore.rules`. `DateTime`s are stored as ISO-8601 strings (via
/// `toJson`), which sort correctly for range/`orderBy`.
class FirestoreOccurrenceRepository implements OccurrenceRepository {
  FirestoreOccurrenceRepository(this._firestore, this._now);

  final FirebaseFirestore _firestore;

  /// Injected clock (never `DateTime.now()` directly — keeps the window floor
  /// deterministic and testable).
  final DateTime Function() _now;

  CollectionReference<Map<String, dynamic>> _ref(String ownerId) =>
      _firestore.collection('users').doc(ownerId).collection('occurrences');

  @override
  Stream<List<TaskOccurrence>> watchOccurrences(String ownerId) {
    final ref = _ref(ownerId);
    final floor = occurrenceWindowFloor(_now());

    List<OccurrenceDoc> toDocs(QuerySnapshot<Map<String, dynamic>> snapshot) =>
        [for (final doc in snapshot.docs) (doc.id, doc.data())];

    // Two bounded queries instead of the whole collection. Neither needs a
    // composite index: the first is a single-field `in`, the second a
    // single-field range (implicitly ordered by that field).
    final open = ref
        .where(
          'status',
          whereIn: [
            OccurrenceStatus.pending.name,
            OccurrenceStatus.rescheduled.name,
          ],
        )
        .snapshots()
        .map(toDocs);
    final recent = ref
        .where('scheduledDate', isGreaterThanOrEqualTo: floor)
        .snapshots()
        .map(toDocs);

    return combineOccurrenceStreams(open, recent);
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
  (ref) => FirestoreOccurrenceRepository(
    ref.watch(firestoreProvider),
    ref.watch(clockProvider),
  ),
);
