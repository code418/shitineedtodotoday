import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/application/settings_providers.dart';
import 'router.dart';
import 'theme.dart';

/// Root widget: wires the router and theming into a [MaterialApp].
class SnitdApp extends ConsumerWidget {
  const SnitdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: ref.watch(appStringsProvider).appTitle,
      debugShowCheckedModeBanner: false,
      // The design system only ships LIGHT colour tokens today; the custom
      // widgets paint hardcoded-light surfaces (e.g. AppColors.surfaceCard).
      // Letting the OS switch to the half-built dark theme turned that text
      // white on those white surfaces — unreadable. Pin to the
      // design-authoritative light theme until real dark tokens land, so the UI
      // stays legible whatever the device's dark-mode setting.
      theme: AppTheme.light(),
      darkTheme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
