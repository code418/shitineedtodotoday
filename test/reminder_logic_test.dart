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

  group('nudgeFallsInQuietHours', () {
    test('true when the nudge time sits inside a wrapping quiet window', () {
      // Quiet 21:00→07:00; nudge 06:30 is inside it → server would suppress.
      const prefs = NotificationPrefs(
        dailyNudgeTime: '06:30',
        quietHoursStart: '21:00',
        quietHoursEnd: '07:00',
      );
      expect(nudgeFallsInQuietHours(prefs), isTrue);
      // And the dispatcher logic agrees it would be suppressed at that time.
      expect(
        shouldSendDailyNudge(
          prefs: prefs,
          nowMinute: 6 * 60 + 30,
          hasOpenTasks: true,
        ),
        isFalse,
      );
    });

    test('false when the nudge time is outside quiet hours', () {
      const prefs = NotificationPrefs(
        dailyNudgeTime: '08:00',
        quietHoursStart: '21:00',
        quietHoursEnd: '07:00',
      );
      expect(nudgeFallsInQuietHours(prefs), isFalse);
    });

    test('false when quiet hours are disabled', () {
      const prefs = NotificationPrefs(
        dailyNudgeTime: '06:30',
        quietHoursEnabled: false,
        quietHoursStart: '21:00',
        quietHoursEnd: '07:00',
      );
      expect(nudgeFallsInQuietHours(prefs), isFalse);
    });

    test('false when the daily nudge is disabled', () {
      const prefs = NotificationPrefs(
        dailyNudgeEnabled: false,
        dailyNudgeTime: '06:30',
        quietHoursStart: '21:00',
        quietHoursEnd: '07:00',
      );
      expect(nudgeFallsInQuietHours(prefs), isFalse);
    });

    test(
      'false when the quiet-end boundary equals the nudge time (exclusive)',
      () {
        // Window end is exclusive, so a nudge exactly at 07:00 is allowed.
        const prefs = NotificationPrefs(
          dailyNudgeTime: '07:00',
          quietHoursStart: '21:00',
          quietHoursEnd: '07:00',
        );
        expect(nudgeFallsInQuietHours(prefs), isFalse);
      },
    );
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

    test(
      'fires once across consecutive ticks (no double-send at boundary)',
      () {
        // Nudge at 08:00 (480), tolerance 14 → window [480, 494].
        // Tick at 480 fires; next tick at 495 must NOT fire.
        expect(
          shouldSendDailyNudge(
            prefs: prefs,
            nowMinute: 480,
            hasOpenTasks: true,
            toleranceMinutes: 14,
          ),
          isTrue,
        );
        expect(
          shouldSendDailyNudge(
            prefs: prefs,
            nowMinute: 495,
            hasOpenTasks: true,
            toleranceMinutes: 14,
          ),
          isFalse,
          reason: 'second tick 15 min later is outside the 14-min window',
        );
      },
    );

    test('wraps past midnight', () {
      // Nudge at 23:50 (1430), tolerance 14 → window [1430, 1443 mod 1440] = [1430, 3].
      // nowMinute 0 (00:00) is inside the window (diff = 10 ≤ 14).
      // nowMinute 1425 (23:45) is before the window (diff = 1435 > 14).
      // Quiet hours are disabled so 00:00 (which falls in the default 21-07
      // window) is not suppressed by them.
      final latePrefs = prefs.copyWith(
        dailyNudgeTime: '23:50',
        quietHoursEnabled: false,
      );
      expect(
        shouldSendDailyNudge(
          prefs: latePrefs,
          nowMinute: 0,
          hasOpenTasks: true,
          toleranceMinutes: 14,
        ),
        isTrue,
        reason: 'midnight (00:00) is 10 min after 23:50, within tolerance',
      );
      expect(
        shouldSendDailyNudge(
          prefs: latePrefs,
          nowMinute: 1425,
          hasOpenTasks: true,
          toleranceMinutes: 14,
        ),
        isFalse,
        reason: '23:45 is 5 min before 23:50, outside the window',
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
