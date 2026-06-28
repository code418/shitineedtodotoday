import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/features/auth/data/auth_repository.dart';
import 'package:snitd/features/auth/domain/account_status.dart';
import 'package:snitd/features/auth/presentation/account_screen.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';

// ── Fake ─────────────────────────────────────────────────────────────────────

/// Minimal [User] stub for ensureSignedIn's return value.
class _FakeUser implements User {
  @override
  String get uid => 'anon-2';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  String? linkedEmail;
  String? linkedPassword;
  bool signedOut = false;
  bool ensureSignedInCalled = false;

  @override
  Stream<User?> userChanges() => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<User> ensureSignedIn() async {
    ensureSignedInCalled = true;
    return _FakeUser();
  }

  @override
  Future<void> signOut() async => signedOut = true;

  @override
  Future<void> linkEmailPassword({
    required String email,
    required String password,
  }) async {
    linkedEmail = email;
    linkedPassword = password;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<ProviderScope> _buildScope({
  required WidgetTester tester,
  required _FakeAuthRepository fake,
  required AccountStatus status,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final scope = ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(fake),
      accountStatusProvider.overrideWithValue(status),
    ],
    child: const MaterialApp(home: AccountScreen()),
  );
  await tester.pumpWidget(scope);
  await tester.pumpAndSettle();
  return scope;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets(
    'entering valid credentials and tapping upgrade calls linkEmailPassword',
    (tester) async {
      final fake = _FakeAuthRepository();
      await _buildScope(
        tester: tester,
        fake: fake,
        status: const AccountStatus(signedIn: true, isAnonymous: true),
      );

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');

      await tester.tap(find.text('Save my account'));
      await tester.pumpAndSettle();

      expect(fake.linkedEmail, 'test@example.com');
    },
  );

  testWidgets('upgraded account shows email and sign out button', (
    tester,
  ) async {
    final fake = _FakeAuthRepository();
    await _buildScope(
      tester: tester,
      fake: fake,
      status: const AccountStatus(
        signedIn: true,
        isAnonymous: false,
        email: 'a@b.com',
      ),
    );

    expect(find.text('a@b.com'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('signing out re-establishes a fresh anonymous session', (
    tester,
  ) async {
    final fake = _FakeAuthRepository();
    await _buildScope(
      tester: tester,
      fake: fake,
      status: const AccountStatus(
        signedIn: true,
        isAnonymous: false,
        email: 'a@b.com',
      ),
    );

    // Tap the Sign out button, then confirm in the dialog.
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out').last);
    await tester.pumpAndSettle();

    expect(fake.signedOut, isTrue);
    // Anonymous-first: a new anonymous session is created so the app stays
    // usable rather than being left ownerless.
    expect(fake.ensureSignedInCalled, isTrue);
  });
}
