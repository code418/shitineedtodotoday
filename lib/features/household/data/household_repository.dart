import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../domain/household.dart';

/// Reads and writes the owner's [Household] document.
abstract interface class HouseholdRepository {
  Stream<Household> watch(String ownerId);
  Future<void> save(String ownerId, Household household);
}

/// Firestore-backed [HouseholdRepository].
///
/// Layout: `users/{ownerId}/meta/household` — owner-scoped by existing rules.
class FirestoreHouseholdRepository implements HouseholdRepository {
  FirestoreHouseholdRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ref(String ownerId) => _firestore
      .collection('users')
      .doc(ownerId)
      .collection('meta')
      .doc('household');

  @override
  Stream<Household> watch(String ownerId) {
    return _ref(ownerId).snapshots().map(
      (d) => d.exists && d.data() != null
          ? Household.fromJson(d.data()!)
          : Household.empty,
    );
  }

  @override
  Future<void> save(String ownerId, Household household) =>
      _ref(ownerId).set(household.toJson());
}

final householdRepositoryProvider = Provider<HouseholdRepository>(
  (ref) => FirestoreHouseholdRepository(ref.watch(firestoreProvider)),
);
