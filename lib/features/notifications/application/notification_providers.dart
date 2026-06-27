import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/application/tasks_providers.dart';
import '../data/notification_prefs_repository.dart';
import '../domain/notification_prefs.dart';

/// Streams the signed-in owner's [NotificationPrefs], falling back to defaults
/// when no owner is available.
final notificationPrefsProvider = StreamProvider<NotificationPrefs>((ref) {
  final uid = ref.watch(currentOwnerIdProvider);
  if (uid == null) return Stream.value(NotificationPrefs.defaults);
  return ref.watch(notificationPrefsRepositoryProvider).watch(uid);
});

/// Handles writes to [NotificationPrefs] for a specific owner.
class NotificationPrefsController {
  NotificationPrefsController({
    required this.repository,
    required this.ownerId,
  });

  final NotificationPrefsRepository repository;
  final String ownerId;

  Future<void> update(NotificationPrefs prefs) =>
      repository.save(ownerId, prefs);
}

/// The active [NotificationPrefsController], or null when there is no
/// signed-in owner.
final notificationPrefsControllerProvider =
    Provider<NotificationPrefsController?>((ref) {
      final uid = ref.watch(currentOwnerIdProvider);
      if (uid == null) return null;
      return NotificationPrefsController(
        repository: ref.watch(notificationPrefsRepositoryProvider),
        ownerId: uid,
      );
    });
