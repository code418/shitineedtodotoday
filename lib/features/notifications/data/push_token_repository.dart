import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';

/// Stores the device's FCM registration token(s) for an owner so the scheduled
/// reminder Cloud Function knows where to push.
abstract interface class PushTokenRepository {
  /// Records (or refreshes) [token] for [ownerId].
  Future<void> register(
    String ownerId, {
    required String token,
    required String platform,
  });

  Future<void> remove(String ownerId, String token);
}

/// Firestore-backed [PushTokenRepository].
///
/// Layout: `users/{ownerId}/tokens/{token}` — the dispatcher reads these and
/// prunes any the device rejects.
class FirestorePushTokenRepository implements PushTokenRepository {
  FirestorePushTokenRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _ref(String ownerId) =>
      _firestore.collection('users').doc(ownerId).collection('tokens');

  @override
  Future<void> register(
    String ownerId, {
    required String token,
    required String platform,
  }) => _ref(ownerId).doc(token).set({
    'token': token,
    'platform': platform,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  @override
  Future<void> remove(String ownerId, String token) =>
      _ref(ownerId).doc(token).delete();
}

final pushTokenRepositoryProvider = Provider<PushTokenRepository>(
  (ref) => FirestorePushTokenRepository(ref.watch(firestoreProvider)),
);
