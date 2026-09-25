import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_providers.dart';
import 'push_registrar.dart';

/// Everything this device must record once it has an owner, so the server-side
/// reminder dispatcher can reach them at the right local time: the FCM token
/// ([PushRegistrar]) and the device's time zone ([TimeZoneRegistrar]).
///
/// App start-up and the post-sign-out re-sign-in both go through here, so the
/// two paths can't drift — a fresh anonymous uid has no prefs doc, and skipping
/// the time-zone write leaves the dispatcher nudging it on London time.
class DeviceRegistration {
  DeviceRegistration(this._ref);

  final Ref _ref;

  /// Best-effort. Each step is read and run independently, so one failing
  /// (e.g. declined notification permission) never skips the other, and
  /// nothing here ever throws to the caller.
  Future<void> registerFor(String ownerId) async {
    try {
      await _ref.read(pushRegistrarProvider).registerFor(ownerId);
    } catch (error, stackTrace) {
      debugPrint('Push registration failed: $error\n$stackTrace');
    }
    try {
      await _ref.read(timeZoneRegistrarProvider).registerFor(ownerId);
    } catch (error, stackTrace) {
      debugPrint('Time-zone registration failed: $error\n$stackTrace');
    }
  }
}

final deviceRegistrationProvider = Provider<DeviceRegistration>(
  DeviceRegistration.new,
);
