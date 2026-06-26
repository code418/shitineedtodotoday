import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';

/// Thin wrapper around [FirebaseAuth] for the app's anonymous-first auth flow.
///
/// The scaffold signs users in anonymously so they can start immediately; a
/// future iteration links the anonymous account to Google / Apple / email
/// (see `docs/ROADMAP.md`, P4).
class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  /// Emits the current user (or `null` when signed out) on every auth change.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Ensures there is a signed-in user, creating an anonymous one if needed.
  Future<User> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  Future<void> signOut() => _auth.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider)),
);

/// Streams the signed-in [User] (or `null`). Used to scope data to the owner.
final authStateChangesProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
