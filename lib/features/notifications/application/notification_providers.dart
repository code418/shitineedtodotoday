import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/application/tasks_providers.dart';
import '../data/device_time_zone.dart';
import '../data/notification_prefs_repository.dart';
import '../domain/notification_prefs.dart';

/// Streams the signed-in owner's [NotificationPrefs], falling back to defaults
/// when no owner is available.
final notificationPrefsProvider = StreamProvider<NotificationPrefs>((ref) {
  final uid = ref.watch(currentOwnerIdProvider);
  if (uid == null) return Stream.value(NotificationPrefs.defaults);
  return ref.watch(notificationPrefsRepositoryProvider).watch(uid);
});

/// Handles writes to [NotificationPrefs] for a specific owner.
class NotificationPrefsController {
  NotificationPrefsController({
    required this.repository,
    required this.ownerId,
  });

  final NotificationPrefsRepository repository;
  final String ownerId;

  Future<void> update(NotificationPrefs prefs) =>
      repository.save(ownerId, prefs);
}

/// The active [NotificationPrefsController], or null when there is no
/// signed-in owner.
final notificationPrefsControllerProvider =
    Provider<NotificationPrefsController?>((ref) {
      final uid = ref.watch(currentOwnerIdProvider);
      if (uid == null) return null;
      return NotificationPrefsController(
        repository: ref.watch(notificationPrefsRepositoryProvider),
        ownerId: uid,
      );
    });

/// Captures the device's IANA time zone into the owner's prefs so the
/// server-side reminder dispatcher can evaluate them in their own zone instead
/// of assuming London. Pure orchestration over the [DeviceTimeZone] seam and
/// the prefs repository, so it's testable without a plugin or Firebase.
class TimeZoneRegistrar {
  TimeZoneRegistrar({required this.device, required this.prefs});

  final DeviceTimeZone device;
  final NotificationPrefsRepository prefs;

  /// Best-effort: read the device zone and, if known, persist just that field
  /// for [ownerId]. A null zone (unknown / unsupported platform) leaves the
  /// stored value untouched.
  Future<void> registerFor(String ownerId) async {
    final zone = await device.current();
    if (zone == null || zone.isEmpty) return;
    await prefs.saveTimeZone(ownerId, zone);
  }
}

final timeZoneRegistrarProvider = Provider<TimeZoneRegistrar>(
  (ref) => TimeZoneRegistrar(
    device: ref.watch(deviceTimeZoneProvider),
    prefs: ref.watch(notificationPrefsRepositoryProvider),
  ),
);
