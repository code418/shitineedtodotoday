import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';

/// A thin seam over [FirebaseMessaging] so the registration coordinator can be
/// unit-tested without the plugin.
abstract interface class PushMessaging {
  /// Asks the OS for notification permission (Android 13+/iOS).
  Future<void> requestPermission();

  /// The current FCM registration token, or null if unavailable.
  Future<String?> getToken();

  /// Emits a new token whenever FCM rotates it.
  Stream<String> get onTokenRefresh;
}

/// [PushMessaging] backed by the real [FirebaseMessaging] plugin.
class FirebasePushMessaging implements PushMessaging {
  FirebasePushMessaging(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Future<void> requestPermission() => _messaging.requestPermission();

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}

final pushMessagingProvider = Provider<PushMessaging>(
  (ref) => FirebasePushMessaging(ref.watch(firebaseMessagingProvider)),
);
