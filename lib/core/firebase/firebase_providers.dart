import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether `Firebase.initializeApp` succeeded at startup.
///
/// Overridden in `main()` with the real value. Defaults to `false` so that
/// widgets/tests that read it without an override behave as "unconfigured"
/// rather than crashing.
final firebaseReadyProvider = Provider<bool>((ref) => false);

/// The active [FirebaseAuth] instance.
///
/// Only read this when [firebaseReadyProvider] is `true`; accessing a Firebase
/// singleton before `Firebase.initializeApp` will throw.
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

/// The active [FirebaseFirestore] instance.
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// The active [FirebaseMessaging] instance (FCM).
final firebaseMessagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);

/// The active [FirebaseAnalytics] instance.
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>(
  (ref) => FirebaseAnalytics.instance,
);
