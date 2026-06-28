import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../domain/account_status.dart';

/// Thin wrapper around [FirebaseAuth] for the app's anonymous-first auth flow.
///
/// The scaffold signs users in anonymously so they can start immediately; a
/// future iteration links the anonymous account to Google / Apple / email
/// (see `docs/ROADMAP.md`, P4).
class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  /// Emits the current user on every auth change *and* on user-property
  /// changes — crucially including [User.linkWithCredential], which keeps the
  /// same uid and so does NOT fire `authStateChanges()`. Account status
  /// (anonymous → linked) must track this stream or the UI won't update after
  /// an in-place upgrade until the next app launch.
  Stream<User?> userChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  /// Ensures there is a signed-in user, creating an anonymous one if needed.
  Future<User> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  Future<void> signOut() => _auth.signOut();

  /// Link the current (anonymous) user to an email/password credential,
  /// upgrading the account in place so the uid — and all their data — is kept.
  Future<void> linkEmailPassword({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user to upgrade.');
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.linkWithCredential(credential);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider)),
);

/// Streams the signed-in [User] (or `null`). Used to scope data to the owner
/// and to drive account status. Backed by `userChanges()` so an in-place
/// account upgrade (link) is reflected immediately.
final userChangesProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).userChanges(),
);

/// Derives account status from the current auth state.
final accountStatusProvider = Provider<AccountStatus>((ref) {
  final user = ref.watch(userChangesProvider).value;
  if (user == null) return AccountStatus.signedOut;
  return AccountStatus(
    signedIn: true,
    isAnonymous: user.isAnonymous,
    email: user.email,
  );
});
