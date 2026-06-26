import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
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
          (snapshot) => snapshot.docs
              .map((doc) => Task.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  @override
  Future<void> upsert(Task task) =>
      _tasksRef(task.ownerId).doc(task.id).set(task.toJson());

  @override
  Future<void> delete(String ownerId, String taskId) =>
      _tasksRef(ownerId).doc(taskId).delete();
}

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => FirestoreTaskRepository(ref.watch(firestoreProvider)),
);
