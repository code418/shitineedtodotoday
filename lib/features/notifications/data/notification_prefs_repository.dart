import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../domain/notification_prefs.dart';

/// Reads and writes the owner's [NotificationPrefs].
///
/// Persisted in Firestore (not just on-device) because reminders are
/// server-driven: the scheduled Cloud Function reads these prefs to decide who
/// to nudge and when.
abstract interface class NotificationPrefsRepository {
  /// Streams the owner's prefs, falling back to [NotificationPrefs.defaults]
  /// until they've saved any.
  Stream<NotificationPrefs> watch(String ownerId);

  Future<void> save(String ownerId, NotificationPrefs prefs);
}

/// Firestore-backed [NotificationPrefsRepository].
///
/// Layout: a single doc `users/{ownerId}/meta/notifications`.
class FirestoreNotificationPrefsRepository
    implements NotificationPrefsRepository {
  FirestoreNotificationPrefsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ref(String ownerId) => _firestore
      .collection('users')
      .doc(ownerId)
      .collection('meta')
      .doc('notifications');

  @override
  Stream<NotificationPrefs> watch(String ownerId) =>
      _ref(ownerId).snapshots().map(
        (doc) => doc.exists && doc.data() != null
            ? NotificationPrefs.fromJson(doc.data()!)
            : NotificationPrefs.defaults,
      );

  @override
  Future<void> save(String ownerId, NotificationPrefs prefs) =>
      _ref(ownerId).set(prefs.toJson());
}

final notificationPrefsRepositoryProvider =
    Provider<NotificationPrefsRepository>(
      (ref) =>
          FirestoreNotificationPrefsRepository(ref.watch(firestoreProvider)),
    );
