import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/design.dart';
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
            child: Row(
              children: [
                Icon(AppIcons.mood, color: AppColors.brand),
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
          const SizedBox(height: AppSpacing.x4),
          AppCard(
            onTap: () => context.push(Routes.household),
            interactive: true,
            child: Row(
              children: [
                Icon(AppIcons.group, color: AppColors.brand),
                const SizedBox(width: AppSpacing.x4),
                Expanded(
                  child: Text(
                    strings.householdSettingsLink,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(AppIcons.expandMore, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppCard(
            onTap: () => context.push(Routes.account),
            interactive: true,
            child: Row(
              children: [
                Icon(AppIcons.person, color: AppColors.brand),
                const SizedBox(width: AppSpacing.x4),
                Expanded(
                  child: Text(
                    strings.accountSettingsLink,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(AppIcons.expandMore, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppCard(
            onTap: () => context.push(Routes.reminders),
            interactive: true,
            child: Row(
              children: [
                Icon(AppIcons.notifications, color: AppColors.brand),
                const SizedBox(width: AppSpacing.x4),
                Expanded(
                  child: Text(
                    strings.remindersSettingsLink,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(AppIcons.expandMore, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppCard(
            onTap: () => context.push(Routes.insights),
            interactive: true,
            child: Row(
              children: [
                Icon(AppIcons.insights, color: AppColors.brand),
                const SizedBox(width: AppSpacing.x4),
                Expanded(
                  child: Text(
                    strings.insightsSettingsLink,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(AppIcons.expandMore, color: AppColors.textMuted),
              ],
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: AppSpacing.x4),
            AppCard(
              onTap: () => context.push(Routes.gallery),
              interactive: true,
              child: Row(
                children: [
                  Icon(AppIcons.checklist, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.x4),
                  const Expanded(child: Text('Design gallery (debug)')),
                  Icon(AppIcons.expandMore, color: AppColors.textMuted),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
