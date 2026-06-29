import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The Web OAuth client id, needed on Android so Google Sign-In returns an
/// `idToken` (the audience Firebase verifies). Supply it at build time:
///
/// ```
/// flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
/// ```
///
/// Find it in the Firebase console (Authentication → Sign-in method → Google →
/// Web SDK configuration) or in `google-services.json` under the
/// `oauth_client` entry with `client_type: 3`. Empty → not configured (iOS
/// reads its client id from the bundled plist, so it can still work there).
const _kServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

/// Seam over Google Sign-In so [AuthRepository] (and the account UI) can be
/// tested without the plugin or its platform channels. Returns a Firebase
/// [AuthCredential] for the chosen Google account, or `null` if the user
/// cancelled the picker. Throws on a genuine failure.
abstract interface class GoogleSignInService {
  Future<AuthCredential?> obtainGoogleCredential();
}

/// Real implementation, backed by the `google_sign_in` plugin (v7 API). This is
/// the only file in the app that imports `google_sign_in`, keeping the rest of
/// the codebase plugin-agnostic and testable.
class GoogleSignInServiceImpl implements GoogleSignInService {
  GoogleSignInServiceImpl({String? serverClientId})
    : _serverClientId = serverClientId ?? _kServerClientId;

  final String _serverClientId;
  bool _initialized = false;

  @override
  Future<AuthCredential?> obtainGoogleCredential() async {
    final google = GoogleSignIn.instance;
    if (!_initialized) {
      await google.initialize(
        serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
      );
      _initialized = true;
    }
    // `authenticate()` is the interactive sign-in; it isn't supported on the
    // web (which uses a rendered button instead). We only call this from
    // mobile, but guard so it fails loudly rather than mysteriously.
    if (!google.supportsAuthenticate()) {
      throw UnsupportedError(
        'Interactive Google sign-in is not supported on this platform.',
      );
    }
    try {
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        // Almost always a missing/incorrect serverClientId (Android) or OAuth
        // client config — surface it instead of handing Firebase a null token.
        throw StateError(
          'Google sign-in returned no idToken — check GOOGLE_SERVER_CLIENT_ID '
          'and the Google provider/OAuth client configuration.',
        );
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      // A cancelled / dismissed picker is not an error — report "no credential".
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }
}

final googleSignInServiceProvider = Provider<GoogleSignInService>(
  (ref) => GoogleSignInServiceImpl(),
);

/// Whether Google sign-in can be offered on this platform/build. Hides the
/// button on the web build (where the interactive flow isn't wired up) and
/// keeps it off in release builds that never configured a server client id on
/// Android (where it would fail for lack of an idToken).
bool googleSignInAvailable() {
  if (kIsWeb) return false;
  return true;
}
