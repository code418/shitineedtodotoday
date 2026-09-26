import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/design.dart';
import '../../home_widget/data/home_widget_bridge.dart';
import '../application/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final profanityEnabled = ref.watch(
      settingsControllerProvider.select((s) => s.profanityEnabled),
    );
    final budget = ref.watch(dailyEnergyBudgetProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.screenPad),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.dailyPaceTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    AppBadge(label: '${budget}m', tone: AppBadgeTone.brand),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  strings.dailyPaceSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Slider(
                  min: 15,
                  max: 180,
                  divisions: 33,
                  value: budget.toDouble(),
                  onChanged: (v) => ref
                      .read(settingsControllerProvider.notifier)
                      .setDailyEnergyBudget(v.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppCard(
            // One screen-reader node: "Profanity mode, …, switch, off".
            child: MergeSemantics(
              child: Row(
                children: [
                  Icon(AppIcons.mood, color: context.palette.brand),
                  const SizedBox(width: AppSpacing.x4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.profanityTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.profanitySubtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  AppSwitch(
                    value: profanityEnabled,
                    onChanged: (v) => ref
                        .read(settingsControllerProvider.notifier)
                        .setProfanityEnabled(v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppCard(
            onTap: () => context.push(Routes.household),
            interactive: true,
            child: Row(
              children: [
                Icon(AppIcons.group, color: context.palette.brand),
                const SizedBox(width: AppSpacing.x4),
                Expanded(
                  child: Text(
                    strings.householdSettingsLink,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(AppIcons.expandMore, color: context.palette.textMuted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppCard(
            onTap: () => context.push(Routes.account),
            interactive: true,
            child: Row(
              children: [
                Icon(AppIcons.person, color: context.palette.brand),
                const SizedBox(width: AppSpacing.x4),
                Expanded(
                  child: Text(
                    strings.accountSettingsLink,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(AppIcons.expandMore, color: context.palette.textMuted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppCard(
            onTap: () => context.push(Routes.reminders),
            interactive: true,
            child: Row(
              children: [
                Icon(AppIcons.notifications, color: context.palette.brand),
                const SizedBox(width: AppSpacing.x4),
                Expanded(
                  child: Text(
                    strings.remindersSettingsLink,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(AppIcons.expandMore, color: context.palette.textMuted),
              ],
            ),
          ),
          // Only where the launcher supports adding widgets from an app
          // (Android 8+, most launchers); elsewhere it's the widget picker.
          if (ref.watch(widgetPinSupportedProvider).value ?? false) ...[
            const SizedBox(height: AppSpacing.x4),
            AppCard(
              onTap: () => ref.read(homeWidgetBridgeProvider).requestPin(),
              interactive: true,
              child: Row(
                children: [
                  Icon(AppIcons.widgets, color: context.palette.brand),
                  const SizedBox(width: AppSpacing.x4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.widgetAddTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.widgetAddBody,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (kDebugMode) ...[
            const SizedBox(height: AppSpacing.x4),
            AppCard(
              onTap: () => context.push(Routes.gallery),
              interactive: true,
              child: Row(
                children: [
                  Icon(
                    AppIcons.checklist,
                    color: context.palette.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.x4),
                  const Expanded(child: Text('Design gallery (debug)')),
                  Icon(AppIcons.expandMore, color: context.palette.textMuted),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
