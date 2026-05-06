import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rehabtech/core/utils/auth_error_messages.dart';
import 'package:rehabtech/router/app_router.dart';

/// Indirection layer over FirebaseAuth so widget tests can drive the screen
/// without touching the platform channel. Production wiring uses
/// [_FirebaseVerifyEmailController]; tests inject a fake.
abstract class VerifyEmailController {
  String? get currentEmail;
  Future<bool> reloadAndCheckVerified();
  Future<void> sendVerificationEmail();
  Future<void> signOut();
}

class _FirebaseVerifyEmailController implements VerifyEmailController {
  @override
  String? get currentEmail => FirebaseAuth.instance.currentUser?.email;

  @override
  Future<bool> reloadAndCheckVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    await user.reload();
    return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> sendVerificationEmail() async {
    await FirebaseAuth.instance.currentUser?.sendEmailVerification();
  }

  @override
  Future<void> signOut() async {
    AppRouter.clearAuthCache();
    await FirebaseAuth.instance.signOut();
  }
}

class VerifyEmailScreen extends StatefulWidget {
  /// Optional in production — defaults to a controller that talks to
  /// FirebaseAuth. Tests pass a fake.
  final VerifyEmailController? controller;

  const VerifyEmailScreen({super.key, this.controller});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late final VerifyEmailController _controller;
  bool _isChecking = false;
  bool _isResending = false;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? _FirebaseVerifyEmailController();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final verified = await _controller.reloadAndCheckVerified();
      if (!mounted) return;
      if (verified) {
        // Router redirect will route to the right home (or onboarding) based
        // on userType + onboardingCompleted.
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aún no verificado. Revisa tu correo y toca el enlace primero.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendEmail() async {
    if (_cooldownSeconds > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await _controller.sendVerificationEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo reenviado')),
      );
      _startCooldown(60);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapResendVerificationError(e))),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> _logout() async {
    await _controller.signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final email = _controller.currentEmail ?? 'tu correo';
    final cooldownActive = _cooldownSeconds > 0;
    final resendLabel =
        cooldownActive ? 'Reenviar en ${_cooldownSeconds}s' : 'Reenviar correo';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: scheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Verifica tu correo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'Enviamos un enlace a\n'),
                    TextSpan(
                      text: email,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text:
                          '\nRevisa tu bandeja de entrada (y la carpeta de spam).',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isChecking ? null : _checkVerification,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Ya verifiqué mi correo'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: cooldownActive || _isResending ? null : _resendEmail,
                child: Text(resendLabel),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _logout,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onSurfaceVariant,
                ),
                child: const Text('Cerrar sesión'),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Problemas? Contáctanos en soporte@rehabtech.mx',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
