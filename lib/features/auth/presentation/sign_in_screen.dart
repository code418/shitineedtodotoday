import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/design.dart';
import '../../../core/strings/app_strings.dart';
import '../../settings/application/settings_providers.dart';
import '../application/sign_in_service.dart';
import '../data/auth_repository.dart';
import '../data/google_sign_in_service.dart';
import '../domain/account_validation.dart';
import 'auth_field_decoration.dart';

/// Sign in to an existing account — email/password or Google — bringing any
/// guest chores on this device along (see [SignInService]).
///
/// Reached from the Account screen (guests, including after signing out) and
/// from onboarding's first page ([fromOnboarding]), so a returning user on a
/// new device can skip straight to their list.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({
    super.key,
    this.initialEmail,
    this.fromOnboarding = false,
  });

  /// Prefills the email field (e.g. from an upgrade that found it in use).
  final String? initialEmail;

  /// Signing in from onboarding completes it: the account already has a list.
  final bool fromOnboarding;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late final _emailCtrl = TextEditingController(text: widget.initialEmail);
  final _passwordCtrl = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    final emailErr = validateEmail(_emailCtrl.text);
    final passErr = validatePasswordEntered(_passwordCtrl.text);
    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });
    if (emailErr != null || passErr != null) return;
    await _run(
      () => ref
          .read(signInServiceProvider)
          .signInWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          ),
    );
  }

  Future<void> _signInWithGoogle() =>
      _run(() => ref.read(signInServiceProvider).signInWithGoogle());

  /// Runs one sign-in attempt behind the re-entrancy guard, then lands on
  /// Today with a welcome (or explains the failure and stays put).
  Future<void> _run(Future<SignInResult> Function() attempt) async {
    if (_loading) return;
    final strings = ref.read(appStringsProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      final result = await attempt();
      if (result.cancelled) return;
      if (widget.fromOnboarding) {
        await ref
            .read(settingsControllerProvider.notifier)
            .setOnboardingComplete(true);
      }
      if (!mounted) return;
      context.go(Routes.today);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.mergeFailed
                ? strings.signedInMergeFailed
                : result.mergedTasks > 0
                ? strings.signedInMerged
                : strings.signedInWelcome,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(_messageFor(e.code, strings))),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(strings.signInFailed)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _messageFor(String code, AppStrings strings) => switch (code) {
    // Current Firebase (with email-enumeration protection) reports every bad
    // email/password pair as invalid-credential; older codes kept for safety.
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-email' => strings.signInBadCredentials,
    'too-many-requests' => strings.signInTooManyTries,
    'account-exists-with-different-credential' => strings.signInOtherMethod,
    _ => strings.signInFailed,
  };

  Future<void> _forgotPassword() async {
    final strings = ref.read(appStringsProvider);
    final emailErr = validateEmail(_emailCtrl.text);
    setState(() => _emailError = emailErr);
    if (emailErr != null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordReset(_emailCtrl.text.trim());
      messenger.showSnackBar(
        SnackBar(content: Text(strings.passwordResetSent)),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(strings.actionFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.signInTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.screenPad),
        children: [
          Text(strings.signInIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.x5),

          Text(strings.emailLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.x1),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            decoration: authFieldDecoration(
              context,
              'you@example.com',
              _emailError,
            ),
          ),
          const SizedBox(height: AppSpacing.x4),

          Text(strings.passwordLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.x1),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _signInWithEmail(),
            decoration: authFieldDecoration(
              context,
              '••••••••',
              _passwordError,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading ? null : _forgotPassword,
              child: Text(strings.forgotPassword),
            ),
          ),
          const SizedBox(height: AppSpacing.x2),

          AppButton(
            label: strings.signInCta,
            block: true,
            pill: true,
            onPressed: _loading ? null : _signInWithEmail,
          ),

          if (googleSignInAvailable()) ...[
            const SizedBox(height: AppSpacing.x5),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x3,
                  ),
                  child: Text(
                    strings.orSeparator,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: context.palette.textMuted,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.x5),
            AppButton(
              label: strings.continueWithGoogle,
              variant: AppButtonVariant.tonal,
              block: true,
              pill: true,
              onPressed: _loading ? null : _signInWithGoogle,
            ),
          ],
        ],
      ),
    );
  }
}
