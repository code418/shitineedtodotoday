import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../core/util/firestore_decode.dart';
import '../domain/task.dart';

/// Reads and writes [Task] definitions.
///
/// Implemented against Firestore here; the interface keeps the rest of the app
/// storage-agnostic (handy for tests and for the planned offline-first work).
abstract interface class TaskRepository {
  /// Streams the owner's tasks, newest first.
  Stream<List<Task>> watchTasks(String ownerId);

  Future<void> upsert(Task task);

  Future<void> delete(String ownerId, String taskId);

  /// A fresh, unique id for a new task document owned by [ownerId].
  String newId(String ownerId);
}

/// Firestore-backed [TaskRepository].
///
/// Layout: `users/{ownerId}/tasks/{taskId}` — mirrored by `firestore.rules`
/// so a user can only ever touch their own documents.
class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _tasksRef(String ownerId) =>
      _firestore.collection('users').doc(ownerId).collection('tasks');

  @override
  Stream<List<Task>> watchTasks(String ownerId) {
    return _tasksRef(ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => decodeDocs(
            [for (final doc in snapshot.docs) (doc.id, doc.data())],
            Task.fromJson,
            label: 'task',
          ),
        );
  }

  @override
  Future<void> upsert(Task task) =>
      _tasksRef(task.ownerId).doc(task.id).set(task.toJson());

  @override
  Future<void> delete(String ownerId, String taskId) =>
      _tasksRef(ownerId).doc(taskId).delete();

  @override
  String newId(String ownerId) => _tasksRef(ownerId).doc().id;
}

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => FirestoreTaskRepository(ref.watch(firestoreProvider)),
);
