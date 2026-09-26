import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firebase_setup.dart';
import '../../tasks/application/tasks_providers.dart';
import '../../tasks/data/occurrence_repository.dart';
import '../../tasks/data/task_repository.dart';
import '../data/home_widget_bridge.dart';
import 'widget_completer.dart';

/// Handles a tap on the Android home-screen widget. home_widget runs this in a
/// background isolate — the app may not be open — for the row's
/// `sintdt://complete?occ=<occurrence id>`. Wires the real repositories through
/// the same providers the app uses, then hands off to [WidgetCompleter].
@pragma('vm:entry-point')
Future<void> onHomeWidgetTap(Uri? uri) async {
  final occurrenceId = uri?.host == 'complete'
      ? uri!.queryParameters['occ']
      : null;
  if (occurrenceId == null) return;

  final container = ProviderContainer(
    overrides: [firebaseReadyProvider.overrideWithValue(true)],
  );
  try {
    await initializeFirebaseCore();
    final result = await WidgetCompleter(
      bridge: container.read(homeWidgetBridgeProvider),
      ownerId: container.read(firebaseAuthProvider).currentUser?.uid,
      tasks: container.read(taskRepositoryProvider),
      occurrences: container.read(occurrenceRepositoryProvider),
      now: container.read(clockProvider),
    ).tick(occurrenceId);
    debugPrint('Home widget tick $occurrenceId: ${result.name}');
  } catch (error, stackTrace) {
    debugPrint('Home widget tick failed: $error\n$stackTrace');
  } finally {
    container.dispose();
  }
}
