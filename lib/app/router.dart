import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dev/gallery/gallery_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/tasks/presentation/today_screen.dart';

/// App route names, kept in one place to avoid stringly-typed navigation.
abstract final class Routes {
  static const today = '/';
  static const settings = '/settings';
  static const gallery = '/gallery';
}

/// The app's [GoRouter]. Exposed as a provider so routes can later depend on
/// auth/onboarding state via `ref`.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.today,
    routes: [
      GoRoute(
        path: Routes.today,
        builder: (context, state) => const TodayScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      if (kDebugMode)
        GoRoute(
          path: Routes.gallery,
          builder: (context, state) => const GalleryScreen(),
        ),
    ],
  );
});
