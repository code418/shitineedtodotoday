/// Snapshot of the current user's account state, derived from Firebase Auth.
///
/// Consumers watch [accountStatusProvider] (in `auth_repository.dart`) rather
/// than using FirebaseAuth directly so tests can swap in a plain value.
class AccountStatus {
  const AccountStatus({
    required this.signedIn,
    required this.isAnonymous,
    this.email,
  });

  final bool signedIn;
  final bool isAnonymous;
  final String? email;

  /// Convenience constant for the not-signed-in state.
  static const signedOut = AccountStatus(signedIn: false, isAnonymous: false);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountStatus &&
        other.signedIn == signedIn &&
        other.isAnonymous == isAnonymous &&
        other.email == email;
  }

  @override
  int get hashCode => Object.hash(signedIn, isAnonymous, email);
}
