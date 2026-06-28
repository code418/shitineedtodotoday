import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/strings/app_strings.dart';
import '../../settings/application/settings_providers.dart';
import '../../tasks/application/tasks_providers.dart';
import '../application/notification_providers.dart';
import '../domain/notification_prefs.dart';
import '../domain/reminder_logic.dart';

/// Converts an `HH:mm` string to a [TimeOfDay], falling back to 08:00 if
/// the string is malformed.
TimeOfDay _toTimeOfDay(String hhmm) {
  final minutes = minuteOfDay(hhmm);
  if (minutes == null) return const TimeOfDay(hour: 8, minute: 0);
  return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
}

/// Formats a [TimeOfDay] as `HH:mm`.
String _fmt(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Manages the user's server-driven reminder preferences — daily-nudge timing,
/// quiet hours, an in-app lock-screen preview, and a test-nudge demo.
///
/// All changes are persisted to Firestore where the Cloud Function reads them.
/// There are NO on-device local notifications.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final prefsAsync = ref.watch(notificationPrefsProvider);
    final prefs = prefsAsync.value ?? NotificationPrefs.defaults;
    final controller = ref.watch(notificationPrefsControllerProvider);
    // The push (and the OS notification) is always sent in the clean register,
    // regardless of the in-app profanity toggle, so the preview must mirror the
    // clean copy — not the profanity-aware `strings`.
    const pushStrings = AppStrings.clean;

    void save(NotificationPrefs p) => controller?.update(p);

    final openCount = ref
        .watch(todayChecklistProvider)
        .where((o) => o.isOpen)
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(strings.remindersTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.screenPad),
        children: [
          // ── Daily nudge ────────────────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.notifications, color: context.palette.brand),
                    const SizedBox(width: AppSpacing.x4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.dailyNudgeTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.dailyNudgeSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    AppSwitch(
                      value: prefs.dailyNudgeEnabled,
                      onChanged: (v) =>
                          save(prefs.copyWith(dailyNudgeEnabled: v)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x4),
                _TimeRow(
                  label: strings.reminderTimeLabel,
                  time: prefs.dailyNudgeTime,
                  enabled: prefs.dailyNudgeEnabled,
                  onPick: (picked) =>
                      save(prefs.copyWith(dailyNudgeTime: _fmt(picked))),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.x4),

          // ── Quiet hours ────────────────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.bedtime, color: context.palette.brand),
                    const SizedBox(width: AppSpacing.x4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.quietHoursTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.quietHoursSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    AppSwitch(
                      value: prefs.quietHoursEnabled,
                      onChanged: (v) =>
                          save(prefs.copyWith(quietHoursEnabled: v)),
                    ),
                  ],
                ),
                if (prefs.quietHoursEnabled) ...[
                  const SizedBox(height: AppSpacing.x4),
                  _TimeRow(
                    label: strings.quietStartLabel,
                    time: prefs.quietHoursStart,
                    enabled: true,
                    onPick: (picked) =>
                        save(prefs.copyWith(quietHoursStart: _fmt(picked))),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _TimeRow(
                    label: strings.quietEndLabel,
                    time: prefs.quietHoursEnd,
                    enabled: true,
                    onPick: (picked) =>
                        save(prefs.copyWith(quietHoursEnd: _fmt(picked))),
                  ),
                ],
              ],
            ),
          ),

          // Warn when the chosen nudge time sits inside quiet hours: the server
          // would silently suppress it, so the user would never get a nudge.
          if (nudgeFallsInQuietHours(prefs)) ...[
            const SizedBox(height: AppSpacing.x4),
            AppBanner(
              message: strings.nudgeInQuietHoursWarning,
              tone: AppBannerTone.gentle,
            ),
          ],

          const SizedBox(height: AppSpacing.x6),

          // ── Preview ────────────────────────────────────────────────────────
          Text(
            strings.previewHeading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.x3),
          _LockScreenCard(
            appTitle: pushStrings.appTitle,
            nudgeTime: prefs.dailyNudgeTime,
            body: openCount > 0
                ? pushStrings.nudgeBodyHasTasks
                : pushStrings.nudgeBodyClear,
          ),

          const SizedBox(height: AppSpacing.x4),

          // ── Test nudge button ──────────────────────────────────────────────
          AppButton(
            label: strings.testNudge,
            variant: AppButtonVariant.tonal,
            block: true,
            pill: true,
            icon: AppIcons.notifications,
            onPressed: () => _showTestNudge(context, ref),
          ),

          const SizedBox(height: AppSpacing.x6),
        ],
      ),
    );
  }

  void _showTestNudge(BuildContext context, WidgetRef ref) {
    final strings = ref.read(appStringsProvider);
    // Push copy is always clean (see build); the preview must match.
    const pushStrings = AppStrings.clean;
    final prefs =
        ref.read(notificationPrefsProvider).value ?? NotificationPrefs.defaults;
    final openCount = ref
        .read(todayChecklistProvider)
        .where((o) => o.isOpen)
        .length;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.testNudgeSent)));

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (ctx, animation, _, child) {
        final slide =
            Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return SlideTransition(position: slide, child: child);
      },
      pageBuilder: (ctx, _, _) => Align(
        alignment: Alignment.topCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.screenPad,
              AppSpacing.x4,
              AppLayout.screenPad,
              0,
            ),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: _LockScreenCard(
                  appTitle: pushStrings.appTitle,
                  nudgeTime: prefs.dailyNudgeTime,
                  body: openCount > 0
                      ? pushStrings.nudgeBodyHasTasks
                      : pushStrings.nudgeBodyClear,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

/// A tappable row showing a label and the current time as an [AppBadge].
class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.time,
    required this.enabled,
    required this.onPick,
  });

  final String label;
  final String time;
  final bool enabled;
  final ValueChanged<TimeOfDay> onPick;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _toTimeOfDay(time),
                );
                if (picked != null) onPick(picked);
              }
            : null,
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            AppBadge(label: time, tone: AppBadgeTone.brand),
          ],
        ),
      ),
    );
  }
}

/// In-app "lock screen" preview card — mirrors what the push notification
/// will look like on the device lock screen.
class _LockScreenCard extends StatelessWidget {
  const _LockScreenCard({
    required this.appTitle,
    required this.nudgeTime,
    required this.body,
  });

  final String appTitle;
  final String nudgeTime;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        // Always-dark "lock screen" mock. A subtle border delineates it from
        // the page in dark mode, where the page is also dark ink.
        color: AppColors.ink900,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: context.palette.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBrandMark(size: 36),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appTitle,
                        style: TextStyle(
                          fontFamily: AppTypography.fontSans,
                          fontSize: AppTypography.sizeSm,
                          fontWeight: AppTypography.semibold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    Text(
                      nudgeTime,
                      style: AppTypography.mono(
                        size: AppTypography.sizeXs,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
