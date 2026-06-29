import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../features/settings/application/settings_providers.dart';
import '../../notifications/application/push_registrar.dart';
import '../../tasks/application/tasks_providers.dart';
import '../data/auth_repository.dart';
import '../data/google_sign_in_service.dart';
import '../domain/account_validation.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _emailCtrl = TextEditingController();
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

  /// Shared decoration for the email/password fields: a filled, borderless,
  /// rounded "sunken" input with an optional [errorText].
  InputDecoration _fieldDecoration(String hint, String? errorText) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: context.palette.surfaceSunken,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      errorText: errorText,
    );
  }

  Future<void> _upgrade() async {
    final strings = ref.read(appStringsProvider);
    final emailErr = validateEmail(_emailCtrl.text);
    final passErr = validatePassword(_passwordCtrl.text);
    if (emailErr != null || passErr != null) {
      setState(() {
        _emailError = emailErr;
        _passwordError = passErr;
      });
      return;
    }
    setState(() {
      _emailError = null;
      _passwordError = null;
      _loading = true;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .linkEmailPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.accountUpgraded)));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg =
          e.code == 'email-already-in-use' ||
              e.code == 'credential-already-in-use'
          ? strings.emailInUse
          : e.code == 'weak-password'
          ? strings.weakPassword
          : strings.upgradeFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.upgradeFailed)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    final strings = ref.read(appStringsProvider);
    setState(() => _loading = true);
    try {
      final linked = await ref.read(authRepositoryProvider).linkGoogle();
      if (!mounted) return;
      // linked == false → the user dismissed the Google picker; stay quiet.
      if (linked) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.accountUpgraded)));
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg =
          e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use'
          ? strings.emailInUse
          : strings.upgradeFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.upgradeFailed)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.signOutConfirmTitle),
        content: Text(strings.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final auth = ref.read(authRepositoryProvider);
    // Detach this device from the current owner first, so the dispatcher stops
    // pushing their reminders here once we've signed out. Best-effort — token
    // cleanup must never block sign-out.
    final ownerId = ref.read(currentOwnerIdProvider);
    if (ownerId != null) {
      try {
        await ref.read(pushRegistrarProvider).unregister(ownerId);
      } catch (_) {
        // Ignore; sign out regardless.
      }
    }
    await auth.signOut();
    // Anonymous-first: immediately re-establish a fresh anonymous session so the
    // app stays usable. Without an owner the user can't add tasks and the
    // upgrade form breaks, and there's no sign-in screen to recover — they'd be
    // stuck until the next app launch re-creates an anonymous user.
    try {
      final fresh = await auth.ensureSignedIn();
      await ref.read(pushRegistrarProvider).registerFor(fresh.uid);
    } catch (_) {
      // Best-effort; a failed re-sign-in self-heals on the next app launch.
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final status = ref.watch(accountStatusProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.accountTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.screenPad),
        children: [
          if (status.isAnonymous || !status.signedIn) ...[
            // Guest card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.guestTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.x2),
                  Text(strings.guestBody, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x4),

            // Email field
            Text(strings.emailLabel, style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.x1),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: _fieldDecoration('you@example.com', _emailError),
            ),
            const SizedBox(height: AppSpacing.x4),

            // Password field
            Text(strings.passwordLabel, style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.x1),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: _fieldDecoration('••••••••', _passwordError),
            ),
            const SizedBox(height: AppSpacing.x5),

            AppButton(
              label: strings.upgradeCta,
              block: true,
              pill: true,
              onPressed: _loading ? null : _upgrade,
            ),

            // Google sign-in: a second one-tap way to upgrade the anonymous
            // account in place (kept off the web build, which doesn't wire up
            // the interactive flow).
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
                onPressed: _loading ? null : _continueWithGoogle,
              ),
            ],
          ] else ...[
            // Signed-in card
            AppCard(
              child: Row(
                children: [
                  AppAvatar(name: status.email ?? ''),
                  const SizedBox(width: AppSpacing.x4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.signedInAs,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.palette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          status.email ?? '',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            AppButton(
              label: strings.signOut,
              variant: AppButtonVariant.ghost,
              onPressed: _signOut,
            ),
          ],
        ],
      ),
    );
  }
}
