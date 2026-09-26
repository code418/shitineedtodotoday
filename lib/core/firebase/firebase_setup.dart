import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Initialises Firebase with the app's Firestore settings. Shared by app
/// start-up and the home-screen widget's background isolate: the native
/// Firestore instance is per process, so both must configure it identically.
/// Safe to call when Firebase is already up. Throws if Firebase isn't
/// configured (the placeholder `firebase_options.dart`).
Future<void> initializeFirebaseCore() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  // Offline-first: cache the owner's data on-device so the checklist works
  // without a connection and syncs when it returns.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}
