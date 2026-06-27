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

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.screenPad),
        children: [
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
