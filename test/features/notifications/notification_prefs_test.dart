import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/notifications/domain/notification_prefs.dart';

void main() {
  group('NotificationPrefs.timeZone', () {
    test('round-trips through toJson/fromJson', () {
      const prefs = NotificationPrefs(timeZone: 'America/New_York');
      final decoded = NotificationPrefs.fromJson(prefs.toJson());
      expect(decoded.timeZone, 'America/New_York');
      expect(decoded, prefs);
    });

    test('defaults to Europe/London when absent', () {
      // A pre-migration doc written before the field existed.
      final decoded = NotificationPrefs.fromJson(const {
        'dailyNudgeTime': '08:00',
      });
      expect(decoded.timeZone, NotificationPrefs.defaultTimeZone);
      expect(decoded.timeZone, 'Europe/London');
    });

    test('falls back defensively on a wrong-typed or empty value', () {
      // Mirrors the server's prefsFromDoc: a bad field must not throw inside the
      // single-doc stream .map and blank the reminders screen.
      expect(
        NotificationPrefs.fromJson(const {'timeZone': 42}).timeZone,
        'Europe/London',
      );
      expect(
        NotificationPrefs.fromJson(const {'timeZone': ''}).timeZone,
        'Europe/London',
      );
    });

    test('is part of equality and copyWith', () {
      const base = NotificationPrefs();
      expect(base.timeZone, 'Europe/London');
      final moved = base.copyWith(timeZone: 'Asia/Kolkata');
      expect(moved.timeZone, 'Asia/Kolkata');
      expect(moved == base, isFalse);
      // copyWith without the arg preserves the zone.
      expect(moved.copyWith(dailyNudgeTime: '09:00').timeZone, 'Asia/Kolkata');
    });
  });
}
