import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/firebase/firebase_providers.dart';
import 'core/firebase/firebase_setup.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/home_widget/application/widget_background.dart';
import 'features/home_widget/data/home_widget_bridge.dart';
import 'features/notifications/application/device_registration.dart';
import 'features/settings/application/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseReady = await _initializeFirebase();
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      firebaseReadyProvider.overrideWithValue(firebaseReady),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  if (firebaseReady) {
    // Anonymous-first: get a user signed in so synced data has an owner.
    unawaited(_ensureSignedIn(container));
    // Taps on the Android home-screen widget run onHomeWidgetTap in the
    // background. Best-effort: the app works without the widget.
    unawaited(
      container
          .read(homeWidgetBridgeProvider)
          .registerTapHandler(onHomeWidgetTap)
          .catchError((Object e) => debugPrint('Widget handler: $e')),
    );
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const SnitdApp()),
  );
}

/// Initialises Firebase and Crashlytics.
///
/// Returns whether it succeeded. A missing `flutterfire configure` (i.e. the
/// committed placeholder `firebase_options.dart`) is caught so the app still
/// boots into an unconfigured/offline mode instead of crashing.
Future<bool> _initializeFirebase() async {
  try {
    await initializeFirebaseCore();
  } catch (error, stackTrace) {
    debugPrint('Firebase not initialised: $error\n$stackTrace');
    return false;
  }

  // Route uncaught Flutter & platform errors to Crashlytics (release only).
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  return true;
}

Future<void> _ensureSignedIn(ProviderContainer container) async {
  try {
    final user = await container.read(authRepositoryProvider).ensureSignedIn();
    // Register this device for server-scheduled reminders (Cloud Function ->
    // FCM) and capture its time zone, so nudges land at the user's local
    // wall-clock time. Best-effort; never blocks the app.
    await container.read(deviceRegistrationProvider).registerFor(user.uid);
  } catch (error, stackTrace) {
    debugPrint('Anonymous sign-in failed: $error\n$stackTrace');
  }
}
