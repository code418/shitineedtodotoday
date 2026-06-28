import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dev/gallery/gallery_screen.dart';
import '../features/auth/presentation/account_screen.dart';
import '../features/household/presentation/household_screen.dart';
import '../features/notifications/presentation/reminders_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/settings/application/settings_providers.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/tasks/presentation/task_detail_screen.dart';
import 'home_shell.dart';

/// App route names, kept in one place to avoid stringly-typed navigation.
abstract final class Routes {
  static const today = '/';
  static const onboarding = '/onboarding';
  static const settings = '/settings';
  static const account = '/account';
  static const reminders = '/reminders';
  static const household = '/household';
  static const insights = '/insights';
  static const schedule = '/schedule';
  static const gallery = '/gallery';
  static const taskDetail = '/task/:id';

  /// Builds the concrete path for a task's detail screen.
  static String taskDetailPath(String id) => '/task/$id';
}

/// The app's [GoRouter]. Exposed as a provider so routes can later depend on
/// auth/onboarding state via `ref`.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.today,
    // Any unmatched route (a stale deep link, a typo'd path) degrades to the
    // shell instead of go_router's raw error page.
    errorBuilder: (context, state) => const HomeShell(),
    redirect: (context, state) {
      final done = ref.read(settingsControllerProvider).onboardingComplete;
      final atOnboarding = state.matchedLocation == Routes.onboarding;
      // Until onboarding is complete, every entry point — including deep links
      // and notification taps to e.g. /schedule or /task/:id — funnels through
      // onboarding, not just a launch on the Today tab.
      if (!done && !atOnboarding) {
        return Routes.onboarding;
      }
      if (done && atOnboarding) {
        return Routes.today;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.today,
        builder: (context, state) => const HomeShell(),
      ),
      // Schedule and Insights are tabs inside the shell; these routes let a
      // deep link / notification tap open the shell on the matching tab.
      GoRoute(
        path: Routes.schedule,
        builder: (context, state) => const HomeShell(initialTab: 1),
      ),
      GoRoute(
        path: Routes.insights,
        builder: (context, state) => const HomeShell(initialTab: 2),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.account,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: Routes.reminders,
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: Routes.household,
        builder: (context, state) => const HouseholdScreen(),
      ),
      GoRoute(
        path: Routes.taskDetail,
        builder: (context, state) =>
            TaskDetailScreen(taskId: state.pathParameters['id']!),
      ),
      if (kDebugMode)
        GoRoute(
          path: Routes.gallery,
          builder: (context, state) => const GalleryScreen(),
        ),
    ],
  );
});
