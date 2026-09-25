import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/notifications/application/device_registration.dart';
import 'package:snitd/features/notifications/application/notification_providers.dart';
import 'package:snitd/features/notifications/application/push_registrar.dart';
import 'package:snitd/features/notifications/data/device_time_zone.dart';
import 'package:snitd/features/notifications/data/notification_prefs_repository.dart';
import 'package:snitd/features/notifications/domain/notification_prefs.dart';

import '../../push_registrar_test.dart'
    show FakePushMessaging, FakePushTokenRepository;

class _FakeDeviceTimeZone implements DeviceTimeZone {
  _FakeDeviceTimeZone(this._zone);
  final String? _zone;
  @override
  Future<String?> current() async => _zone;
}

class _RecordingPrefsRepository implements NotificationPrefsRepository {
  final List<(String, String)> timeZoneWrites = [];

  @override
  Stream<NotificationPrefs> watch(String ownerId) =>
      Stream.value(NotificationPrefs.defaults);

  @override
  Future<void> save(String ownerId, NotificationPrefs prefs) async {}

  @override
  Future<void> saveTimeZone(String ownerId, String timeZone) async =>
      timeZoneWrites.add((ownerId, timeZone));
}

/// Push messaging whose permission prompt fails (e.g. the user declined).
class _DecliningPushMessaging extends FakePushMessaging {
  _DecliningPushMessaging() : super('tok');

  @override
  Future<void> requestPermission() async => throw Exception('declined');
}

void main() {
  late _RecordingPrefsRepository prefs;
  late FakePushTokenRepository tokens;

  setUp(() {
    prefs = _RecordingPrefsRepository();
    tokens = FakePushTokenRepository();
  });

  Override timeZone(String? zone) =>
      timeZoneRegistrarProvider.overrideWithValue(
        TimeZoneRegistrar(device: _FakeDeviceTimeZone(zone), prefs: prefs),
      );

  test('registers both the push token and the time zone', () async {
    final container = ProviderContainer(
      overrides: [
        pushRegistrarProvider.overrideWithValue(
          PushRegistrar(
            messaging: FakePushMessaging('tok-1'),
            tokens: tokens,
            platform: 'android',
          ),
        ),
        timeZone('Asia/Tokyo'),
      ],
    );
    addTearDown(container.dispose);

    await container.read(deviceRegistrationProvider).registerFor('u1');

    expect(tokens.registered.single.owner, 'u1');
    expect(prefs.timeZoneWrites, [('u1', 'Asia/Tokyo')]);
  });

  test('a failed push registration never skips the time zone', () async {
    final container = ProviderContainer(
      overrides: [
        pushRegistrarProvider.overrideWithValue(
          PushRegistrar(
            messaging: _DecliningPushMessaging(),
            tokens: tokens,
            platform: 'android',
          ),
        ),
        timeZone('Asia/Tokyo'),
      ],
    );
    addTearDown(container.dispose);

    await container.read(deviceRegistrationProvider).registerFor('u1');

    expect(tokens.registered, isEmpty);
    expect(prefs.timeZoneWrites, [('u1', 'Asia/Tokyo')]);
  });

  test('a push registrar that cannot even be built never skips the time '
      'zone, and nothing is thrown to the caller', () async {
    final container = ProviderContainer(
      overrides: [
        pushRegistrarProvider.overrideWith(
          (ref) => throw StateError('no Firebase messaging'),
        ),
        timeZone('Asia/Tokyo'),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(deviceRegistrationProvider).registerFor('u1'),
      completes,
    );
    expect(prefs.timeZoneWrites, [('u1', 'Asia/Tokyo')]);
  });
}
