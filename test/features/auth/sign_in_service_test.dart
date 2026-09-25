import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/auth/application/sign_in_service.dart';
import 'package:snitd/features/auth/data/auth_repository.dart';
import 'package:snitd/features/notifications/application/notification_providers.dart';
import 'package:snitd/features/notifications/application/push_registrar.dart';
import 'package:snitd/features/notifications/data/device_time_zone.dart';
import 'package:snitd/features/notifications/data/notification_prefs_repository.dart';
import 'package:snitd/features/notifications/domain/notification_prefs.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

import '../../push_registrar_test.dart'
    show FakePushMessaging, FakePushTokenRepository;
import '../../task_service_test.dart' show FakeTaskRepository;

class _User implements User {
  _User(this.uid, {required this.isAnonymous});

  @override
  final String uid;

  @override
  final bool isAnonymous;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Signs in to [account] (or throws [failWith]); tracks the current user.
class _Auth implements AuthRepository {
  _Auth(this._current);

  User? _current;
  User account = _User('acct', isAnonymous: false);
  Object? failWith;
  AuthCredential? googlePick;

  @override
  User? get currentUser => _current;

  Future<User> _signIn() async {
    if (failWith != null) throw failWith!;
    return _current = account;
  }

  @override
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) => _signIn();

  @override
  Future<AuthCredential?> googleCredential() async => googlePick;

  @override
  Future<User> signInWithCredential(AuthCredential credential) => _signIn();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Occurrence store keyed by owner, like the real `users/{uid}/occurrences`.
class _Occurrences implements OccurrenceRepository {
  final Map<String, Map<String, TaskOccurrence>> byOwner = {};

  @override
  Stream<List<TaskOccurrence>> watchOccurrences(String ownerId) =>
      Stream.value([...?byOwner[ownerId]?.values]);

  @override
  Future<void> upsert(String ownerId, TaskOccurrence occurrence) async =>
      (byOwner[ownerId] ??= {})[occurrence.id] = occurrence;

  @override
  Future<void> delete(String ownerId, String occurrenceId) async =>
      byOwner[ownerId]?.remove(occurrenceId);

  @override
  Future<void> deleteForTask(String ownerId, String taskId) async =>
      byOwner[ownerId]?.removeWhere((_, o) => o.taskId == taskId);
}

class _Prefs implements NotificationPrefsRepository {
  final zones = <String>[];

  @override
  Stream<NotificationPrefs> watch(String ownerId) =>
      Stream.value(NotificationPrefs.defaults);

  @override
  Future<void> save(String ownerId, NotificationPrefs prefs) async {}

  @override
  Future<void> saveTimeZone(String ownerId, String timeZone) async =>
      zones.add(ownerId);
}

class _Zone implements DeviceTimeZone {
  @override
  Future<String?> current() async => 'Europe/Paris';
}

/// The account's tasks as this device's cache remembers them (stale) vs as
/// the server has them (truth): a stale copy of an account used here before.
class _StaleCacheTasks extends FakeTaskRepository {
  List<Task> staleAccountCache = const [];

  @override
  Stream<List<Task>> watchTasks(String ownerId) => ownerId == 'acct'
      ? Stream.value(staleAccountCache)
      : super.watchTasks(ownerId);

  @override
  Future<List<Task>> fetchTasksFromServer(String ownerId) async => [
    for (final t in store.values)
      if (t.ownerId == ownerId) t,
  ];
}

/// A token store whose deletes fail (the server can't be reached).
class _FailingRemoveTokens extends FakePushTokenRepository {
  @override
  Future<void> remove(String ownerId, String token) async =>
      throw Exception('unavailable');
}

Task _task(String id, String owner, String title) => Task(
  id: id,
  ownerId: owner,
  title: title,
  recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late _Auth auth;
  late _StaleCacheTasks tasks;
  late _Occurrences occurrences;
  late FakePushTokenRepository tokens;
  late _Prefs prefs;
  late ProviderContainer container;

  setUp(() async {
    auth = _Auth(_User('guest', isAnonymous: true));
    tasks = _StaleCacheTasks()
      ..store['g1'] = _task('g1', 'guest', 'Water plants')
      ..store['g2'] = _task('g2', 'guest', 'Wipe the counters')
      ..store['a1'] = _task('a1', 'acct', 'Wipe the counters');
    occurrences = _Occurrences()
      ..byOwner['guest'] = {
        'g1_2026-06-29': TaskOccurrence(
          id: 'g1_2026-06-29',
          taskId: 'g1',
          scheduledDate: DateTime(2026, 6, 29),
          status: OccurrenceStatus.done,
          completedAt: DateTime(2026, 6, 29, 9),
        ),
      };
    tokens = FakePushTokenRepository();
    prefs = _Prefs();
    final registrar = PushRegistrar(
      messaging: FakePushMessaging('tok'),
      tokens: tokens,
      platform: 'android',
    );
    // The guest's device is registered, as start-up leaves it.
    await registrar.registerFor('guest');
    tokens.registered.clear();

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        taskRepositoryProvider.overrideWithValue(tasks),
        occurrenceRepositoryProvider.overrideWithValue(occurrences),
        pushRegistrarProvider.overrideWithValue(registrar),
        timeZoneRegistrarProvider.overrideWithValue(
          TimeZoneRegistrar(device: _Zone(), prefs: prefs),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  SignInService service() => container.read(signInServiceProvider);

  test('brings the guest\'s chores + history into the account and moves the '
      'device over', () async {
    final result = await service().signInWithEmail(
      email: 'a@b.com',
      password: 'secret123',
    );

    expect(result.cancelled, isFalse);
    expect(result.mergedTasks, 1);
    expect(result.mergeFailed, isFalse);
    // "Water plants" is new to the account; "Wipe the counters" it already
    // had, so it isn't duplicated.
    final accountTitles = [
      for (final t in tasks.store.values)
        if (t.ownerId == 'acct') t.title,
    ];
    expect(
      accountTitles,
      unorderedEquals(['Wipe the counters', 'Water plants']),
    );
    expect(occurrences.byOwner['acct']!.keys, ['g1_2026-06-29']);

    // The guest's token is detached (else it's nudged for the leftover copy)
    // and the account is registered, in this device's zone.
    expect(tokens.removed.map((r) => r.owner), ['guest']);
    expect(tokens.registered.map((r) => r.owner), ['acct']);
    expect(prefs.zones, ['acct']);
  });

  test('a failed sign-in re-attaches the guest and writes nothing', () async {
    auth.failWith = FirebaseAuthException(code: 'invalid-credential');

    await expectLater(
      service().signInWithEmail(email: 'a@b.com', password: 'wrong'),
      throwsA(isA<FirebaseAuthException>()),
    );

    expect(auth.currentUser!.uid, 'guest');
    expect(tokens.registered.map((r) => r.owner), ['guest']);
    expect(occurrences.byOwner['acct'], isNull);
    expect(tasks.store.values.where((t) => t.ownerId == 'acct'), hasLength(1));
  });

  test('dismissing the Google picker changes nothing', () async {
    auth.googlePick = null;

    final result = await service().signInWithGoogle();

    expect(result.cancelled, isTrue);
    expect(tokens.removed, isEmpty);
    expect(auth.currentUser!.uid, 'guest');
  });

  test('a guest with no chores just signs in', () async {
    tasks.store.removeWhere((_, t) => t.ownerId == 'guest');

    final result = await service().signInWithEmail(
      email: 'a@b.com',
      password: 'secret123',
    );

    expect(result.mergedTasks, 0);
    expect(tokens.registered.map((r) => r.owner), ['acct']);
  });

  test('the duplicate check sees the account as the server has it, not a '
      'stale cached copy', () async {
    // This device once held the account's list, including "Water plants",
    // since deleted elsewhere. Trusting that cache would drop the guest's own
    // "Water plants" — and its history — as a false duplicate.
    tasks.staleAccountCache = [_task('old', 'acct', 'Water plants')];

    final result = await service().signInWithEmail(
      email: 'a@b.com',
      password: 'secret123',
    );

    expect(result.mergedTasks, 1);
    expect([
      for (final t in tasks.store.values)
        if (t.ownerId == 'acct') t.title,
    ], contains('Water plants'));
  });

  test(
    'if the guest\'s token can\'t be detached, the switch is abandoned',
    () async {
      // Once signed in elsewhere the device can never remove it (owner-only
      // rules), and it would be nudged for the guest's leftover copy forever.
      final failing = _FailingRemoveTokens();
      final registrar = PushRegistrar(
        messaging: FakePushMessaging('tok'),
        tokens: failing,
        platform: 'android',
      );
      await registrar.registerFor('guest');
      failing.registered.clear();
      final c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          taskRepositoryProvider.overrideWithValue(tasks),
          occurrenceRepositoryProvider.overrideWithValue(occurrences),
          pushRegistrarProvider.overrideWithValue(registrar),
          timeZoneRegistrarProvider.overrideWithValue(
            TimeZoneRegistrar(device: _Zone(), prefs: prefs),
          ),
        ],
      );
      addTearDown(c.dispose);

      await expectLater(
        c
            .read(signInServiceProvider)
            .signInWithEmail(email: 'a@b.com', password: 'secret123'),
        throwsA(isA<Exception>()),
      );

      expect(auth.currentUser!.uid, 'guest', reason: 'never switched');
      expect(failing.registered.map((r) => r.owner), ['guest']);
      expect(occurrences.byOwner['acct'], isNull);
      expect(
        tasks.store.values.where((t) => t.ownerId == 'acct'),
        hasLength(1),
      );
    },
  );
}
