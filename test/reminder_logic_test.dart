import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/notifications/domain/notification_prefs.dart';
import 'package:snitd/features/notifications/domain/reminder_logic.dart';

void main() {
  group('minuteOfDay', () {
    test('parses valid HH:mm', () {
      expect(minuteOfDay('00:00'), 0);
      expect(minuteOfDay('08:30'), 8 * 60 + 30);
      expect(minuteOfDay('23:59'), 23 * 60 + 59);
    });
    test('rejects malformed or out-of-range', () {
      expect(minuteOfDay('8'), isNull);
      expect(minuteOfDay('24:00'), isNull);
      expect(minuteOfDay('10:60'), isNull);
      expect(minuteOfDay('aa:bb'), isNull);
    });
  });

  group('isWithinQuietHours', () {
    test('non-wrapping window', () {
      // 13:00–14:00
      const s = 13 * 60, e = 14 * 60;
      expect(
        isWithinQuietHours(nowMinute: 13 * 60, startMinute: s, endMinute: e),
        isTrue,
      );
      expect(
        isWithinQuietHours(
          nowMinute: 13 * 60 + 30,
          startMinute: s,
          endMinute: e,
        ),
        isTrue,
      );
      expect(
        isWithinQuietHours(nowMinute: 14 * 60, startMinute: s, endMinute: e),
        isFalse,
      ); // end exclusive
      expect(
        isWithinQuietHours(nowMinute: 12 * 60, startMinute: s, endMinute: e),
        isFalse,
      );
    });
    test('window wrapping past midnight (21:00–07:00)', () {
      const s = 21 * 60, e = 7 * 60;
      expect(
        isWithinQuietHours(nowMinute: 23 * 60, startMinute: s, endMinute: e),
        isTrue,
      );
      expect(
        isWithinQuietHours(nowMinute: 2 * 60, startMinute: s, endMinute: e),
        isTrue,
      );
      expect(
        isWithinQuietHours(nowMinute: 7 * 60, startMinute: s, endMinute: e),
        isFalse,
      );
      expect(
        isWithinQuietHours(nowMinute: 12 * 60, startMinute: s, endMinute: e),
        isFalse,
      );
    });
    test('empty window means never quiet', () {
      expect(
        isWithinQuietHours(nowMinute: 600, startMinute: 600, endMinute: 600),
        isFalse,
      );
    });
  });

  group('shouldSendDailyNudge', () {
    const prefs = NotificationPrefs(
      dailyNudgeEnabled: true,
      dailyNudgeTime: '08:00',
      quietHoursEnabled: true,
      quietHoursStart: '21:00',
      quietHoursEnd: '07:00',
    );

    test('fires at the nudge time when there is something to do', () {
      expect(
        shouldSendDailyNudge(
          prefs: prefs,
          nowMinute: 8 * 60,
          hasOpenTasks: true,
        ),
        isTrue,
      );
    });

    test('does not fire when nothing is open', () {
      expect(
        shouldSendDailyNudge(
          prefs: prefs,
          nowMinute: 8 * 60,
          hasOpenTasks: false,
        ),
        isFalse,
      );
    });

    test('does not fire before/after the nudge minute (no tolerance)', () {
      expect(
        shouldSendDailyNudge(
          prefs: prefs,
          nowMinute: 8 * 60 - 1,
          hasOpenTasks: true,
        ),
        isFalse,
      );
      expect(
        shouldSendDailyNudge(
          prefs: prefs,
          nowMinute: 8 * 60 + 1,
          hasOpenTasks: true,
        ),
        isFalse,
      );
    });

    test('tolerance widens the firing window', () {
      expect(
        shouldSendDailyNudge(
          prefs: prefs,
          nowMinute: 8 * 60 + 10,
          hasOpenTasks: true,
          toleranceMinutes: 15,
        ),
        isTrue,
      );
    });

    test('disabled nudge never fires', () {
      expect(
        shouldSendDailyNudge(
          prefs: prefs.copyWith(dailyNudgeEnabled: false),
          nowMinute: 8 * 60,
          hasOpenTasks: true,
        ),
        isFalse,
      );
    });

    test('suppressed inside quiet hours', () {
      // Nudge at 06:00 but quiet hours 21:00–07:00 covers it.
      final early = prefs.copyWith(dailyNudgeTime: '06:00');
      expect(
        shouldSendDailyNudge(
          prefs: early,
          nowMinute: 6 * 60,
          hasOpenTasks: true,
        ),
        isFalse,
      );
      // With quiet hours off, the same nudge fires.
      expect(
        shouldSendDailyNudge(
          prefs: early.copyWith(quietHoursEnabled: false),
          nowMinute: 6 * 60,
          hasOpenTasks: true,
        ),
        isTrue,
      );
    });
  });

  group('NotificationPrefs', () {
    test('survives a JSON round-trip', () {
      const prefs = NotificationPrefs(
        dailyNudgeEnabled: false,
        dailyNudgeTime: '09:15',
        quietHoursEnabled: true,
        quietHoursStart: '22:30',
        quietHoursEnd: '06:45',
      );
      expect(NotificationPrefs.fromJson(prefs.toJson()), prefs);
    });
    test('fromJson tolerates missing keys via defaults', () {
      expect(NotificationPrefs.fromJson(const {}), NotificationPrefs.defaults);
    });
  });
}
