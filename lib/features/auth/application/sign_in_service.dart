import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/application/device_registration.dart';
import '../../notifications/application/push_registrar.dart';
import '../../tasks/data/occurrence_repository.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/domain/scheduling/task_occurrence.dart';
import '../../tasks/domain/task.dart';
import '../data/auth_repository.dart';
import '../domain/guest_merge.dart';

/// How a sign-in attempt ended (failures throw instead).
class SignInResult {
  const SignInResult({
    required this.cancelled,
    this.mergedTasks = 0,
    this.mergeFailed = false,
  });

  static const cancel = SignInResult(cancelled: true);

  /// The user backed out (e.g. dismissed the Google picker); nothing changed.
  final bool cancelled;

  /// Guest chores copied into the account.
  final int mergedTasks;

  /// Signed in, but copying the guest's chores across failed.
  final bool mergeFailed;
}

/// Signs this device in to an existing account, bringing the guest's chores
/// along. Every entry point (sign-in screen, "sign in instead") goes through
/// here so the switch always happens in the same, safe order:
///
/// 1. Snapshot the guest's tasks + history — owner-only rules lock the device
///    out of the guest's data the moment it's signed in to another uid.
/// 2. Detach this device's push token from the outgoing owner (that also needs
///    its auth), or the dispatcher keeps nudging here for the guest's copy.
/// 3. Sign in. On failure (wrong password…) the device is re-registered for
///    the previous owner, so nothing is lost by a typo.
/// 4. Merge the guest's chores into the account ([planGuestMerge]).
/// 5. Register the device for the account's nudges, in its time zone.
///
/// The guest's own documents stay behind, unreachable (a copy, not a move):
/// they can't be deleted before the switch in case sign-in fails, nor after it.
class SignInService {
  SignInService(this._ref);

  final Ref _ref;

  Future<SignInResult> signInWithEmail({
    required String email,
    required String password,
  }) => _switchTo(
    (auth) => auth.signInWithEmail(email: email, password: password),
  );

  /// Google picker first: a cancel returns [SignInResult.cancel] before
  /// anything about the current session is touched.
  Future<SignInResult> signInWithGoogle() async {
    final credential = await _ref
        .read(authRepositoryProvider)
        .googleCredential();
    if (credential == null) return SignInResult.cancel;
    return signInWithCredential(credential);
  }

  Future<SignInResult> signInWithCredential(AuthCredential credential) =>
      _switchTo((auth) => auth.signInWithCredential(credential));

  Future<SignInResult> _switchTo(
    Future<User> Function(AuthRepository auth) signIn,
  ) async {
    final auth = _ref.read(authRepositoryProvider);
    final tasks = _ref.read(taskRepositoryProvider);
    final occurrences = _ref.read(occurrenceRepositoryProvider);
    final previous = auth.currentUser;
    final guestId = previous != null && previous.isAnonymous
        ? previous.uid
        : null;

    var guestTasks = const <Task>[];
    var guestOccurrences = const <TaskOccurrence>[];
    if (guestId != null) {
      guestTasks = await tasks.watchTasks(guestId).first;
      if (guestTasks.isNotEmpty) {
        guestOccurrences = await occurrences.watchOccurrences(guestId).first;
      }
    }

    if (previous != null) {
      try {
        await _ref.read(pushRegistrarProvider).unregister(previous.uid);
      } catch (error) {
        debugPrint('Push unregister before sign-in failed: $error');
      }
    }

    final User user;
    try {
      user = await signIn(auth);
    } catch (_) {
      if (previous != null) {
        await _ref.read(deviceRegistrationProvider).registerFor(previous.uid);
      }
      rethrow;
    }

    var merged = 0;
    var mergeFailed = false;
    if (guestTasks.isNotEmpty) {
      try {
        final plan = planGuestMerge(
          guestTasks: guestTasks,
          guestOccurrences: guestOccurrences,
          accountTasks: await tasks.watchTasks(user.uid).first,
          accountOwnerId: user.uid,
        );
        for (final task in plan.tasks) {
          await tasks.upsert(task);
        }
        for (final occurrence in plan.occurrences) {
          await occurrences.upsert(user.uid, occurrence);
        }
        merged = plan.tasks.length;
      } catch (error) {
        debugPrint('Merging guest tasks failed: $error');
        mergeFailed = true;
      }
    }

    await _ref.read(deviceRegistrationProvider).registerFor(user.uid);
    return SignInResult(
      cancelled: false,
      mergedTasks: merged,
      mergeFailed: mergeFailed,
    );
  }
}

final signInServiceProvider = Provider<SignInService>(SignInService.new);
