// PLACEHOLDER Firebase configuration.
//
// This file is intentionally committed without real project values so the
// scaffold compiles, but it will THROW at runtime until you generate the real
// one for your own Firebase project:
//
//     dart pub global activate flutterfire_cli
//     flutterfire configure
//
// `flutterfire configure` overwrites this file with `DefaultFirebaseOptions`
// for each platform. See `firebase_options.dart.example` and the README
// ("Firebase setup") for the full walkthrough.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Replace this file by running `flutterfire configure`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase has not been configured for this project yet.\n'
      'Run `flutterfire configure` to generate lib/firebase_options.dart '
      'with your own Firebase project values. '
      'Until then the app runs in an unconfigured (offline) mode.',
    );
  }
}
