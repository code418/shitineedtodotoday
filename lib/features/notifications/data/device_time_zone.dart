import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

/// Seam over the device's IANA time-zone lookup.
///
/// The ONLY file that imports `flutter_timezone` (same pattern as
/// `GoogleSignInService` wrapping `google_sign_in`), so the rest of the app —
/// and its tests — depend on this small interface rather than a plugin with a
/// platform channel that no-ops under the Flutter test binding.
abstract interface class DeviceTimeZone {
  /// The device's current IANA zone (e.g. `Europe/London`), or null if it
  /// can't be determined.
  Future<String?> current();
}

/// `flutter_timezone`-backed [DeviceTimeZone].
class FlutterDeviceTimeZone implements DeviceTimeZone {
  const FlutterDeviceTimeZone();

  @override
  Future<String?> current() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final id = info.identifier;
      return id.isEmpty ? null : id;
    } catch (_) {
      // Any platform/channel failure just means "unknown zone" — the caller
      // leaves the stored zone as-is and the dispatcher falls back to London.
      return null;
    }
  }
}

final deviceTimeZoneProvider = Provider<DeviceTimeZone>(
  (ref) => const FlutterDeviceTimeZone(),
);
