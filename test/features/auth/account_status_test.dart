import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/auth/data/auth_repository.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';

/// Minimal [User] stub — only the members account status reads are real; the
/// rest route through noSuchMethod (never invoked by the providers under test).
class _FakeUser implements User {
  _FakeUser({required this.isAnonymous, this.email});

  @override
  final bool isAnonymous;
  @override
  final String? email;
  @override
  final String uid = 'u1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Auth repo whose [userChanges] is driven by a test-controlled stream.
class _StreamAuthRepository implements AuthRepository {
  _StreamAuthRepository(this._stream);

  final Stream<User?> _stream;

  @override
  Stream<User?> userChanges() => _stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'accountStatusProvider tracks an in-place link upgrade via userChanges',
    () async {
      final controller = StreamController<User?>();
      addTearDown(controller.close);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _StreamAuthRepository(controller.stream),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Subscribe so the underlying StreamProvider activates.
      container.listen(accountStatusProvider, (_, _) {}, fireImmediately: true);

      // Anonymous guest first.
      controller.add(_FakeUser(isAnonymous: true));
      await pumpEventQueue();
      expect(container.read(accountStatusProvider).isAnonymous, isTrue);
      expect(container.read(currentOwnerIdProvider), 'u1');

      // linkWithCredential keeps the same uid but flips isAnonymous and sets
      // the email — userChanges() emits this; authStateChanges() would not.
      controller.add(_FakeUser(isAnonymous: false, email: 'a@b.com'));
      await pumpEventQueue();

      final status = container.read(accountStatusProvider);
      expect(status.isAnonymous, isFalse);
      expect(status.email, 'a@b.com');
      // uid is unchanged, so data stays scoped to the same owner.
      expect(container.read(currentOwnerIdProvider), 'u1');
    },
  );
}
