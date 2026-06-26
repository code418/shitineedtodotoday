import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        children: [
          SwitchListTile(
            value: profanityEnabled,
            onChanged: (value) => ref
                .read(settingsControllerProvider.notifier)
                .setProfanityEnabled(value),
            title: Text(strings.profanityTitle),
            subtitle: Text(strings.profanitySubtitle),
            secondary: const Icon(Icons.sentiment_very_satisfied),
          ),
        ],
      ),
    );
  }
}
