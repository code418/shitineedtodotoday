import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/notifications/application/notification_providers.dart';
import 'package:snitd/features/notifications/data/device_time_zone.dart';
import 'package:snitd/features/notifications/data/notification_prefs_repository.dart';
import 'package:snitd/features/notifications/domain/notification_prefs.dart';

class _FakeDeviceTimeZone implements DeviceTimeZone {
  _FakeDeviceTimeZone(this._zone);
  final String? _zone;
  @override
  Future<String?> current() async => _zone;
}

/// Records saveTimeZone calls; every other method is unused here.
class _RecordingPrefsRepository implements NotificationPrefsRepository {
  final List<(String, String)> timeZoneWrites = [];
  var fullSaves = 0;

  @override
  Stream<NotificationPrefs> watch(String ownerId) =>
      Stream.value(NotificationPrefs.defaults);

  @override
  Future<void> save(String ownerId, NotificationPrefs prefs) async {
    fullSaves++;
  }

  @override
  Future<void> saveTimeZone(String ownerId, String timeZone) async {
    timeZoneWrites.add((ownerId, timeZone));
  }
}

void main() {
  test('persists the device zone for the owner', () async {
    final repo = _RecordingPrefsRepository();
    final registrar = TimeZoneRegistrar(
      device: _FakeDeviceTimeZone('America/New_York'),
      prefs: repo,
    );

    await registrar.registerFor('u1');

    expect(repo.timeZoneWrites, [('u1', 'America/New_York')]);
    // Only the merge-write is used — never a full save that could clobber a
    // nudge time the user set.
    expect(repo.fullSaves, 0);
  });

  test('writes nothing when the device zone is unknown', () async {
    final repo = _RecordingPrefsRepository();
    await TimeZoneRegistrar(
      device: _FakeDeviceTimeZone(null),
      prefs: repo,
    ).registerFor('u1');
    expect(repo.timeZoneWrites, isEmpty);
  });

  test('writes nothing for an empty zone string', () async {
    final repo = _RecordingPrefsRepository();
    await TimeZoneRegistrar(
      device: _FakeDeviceTimeZone(''),
      prefs: repo,
    ).registerFor('u1');
    expect(repo.timeZoneWrites, isEmpty);
  });
}
