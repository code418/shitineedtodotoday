import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home_widget/application/widget_sync.dart';
import '../features/settings/application/settings_providers.dart';
import 'router.dart';
import 'theme.dart';

/// Root widget: wires the router and theming into a [MaterialApp].
class SnitdApp extends ConsumerWidget {
  const SnitdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Keep the Android home-screen widget in step with Today for the app's
    // whole life (listen, not watch: it never needs to rebuild the app).
    ref.listen(widgetSyncProvider, (_, _) {});
    return MaterialApp.router(
      title: ref.watch(appStringsProvider).appTitle,
      debugShowCheckedModeBanner: false,
      // Widgets resolve their surface/text/border colours from the AppPalette
      // theme extension (light + dark token sets), so the app follows the
      // device's light/dark setting.
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
