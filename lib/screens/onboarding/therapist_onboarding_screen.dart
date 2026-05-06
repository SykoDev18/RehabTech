import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:rehabtech/router/app_router.dart';

const _kSpecialities = <String>[
  'Fisioterapia',
  'Rehabilitación Física',
  'Kinesiología',
  'Terapia Física',
  'Terapia Ocupacional',
  'Otra',
];

const _kModalities = <String>['Presencial', 'Virtual', 'Ambas'];

/// Four-step welcome flow shown once for newly registered therapists.
/// Gated by `users/{uid}.onboardingCompleted` — the GoRouter redirect
/// pushes therapists here until that flag is `true`.
class TherapistOnboardingScreen extends StatefulWidget {
  /// Optional injection seams for tests; production wiring uses the global
  /// singletons.
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;

  const TherapistOnboardingScreen({super.key, this.firestore, this.auth});

  @override
  State<TherapistOnboardingScreen> createState() =>
      _TherapistOnboardingScreenState();
}

class _TherapistOnboardingScreenState extends State<TherapistOnboardingScreen> {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  final PageController _pageController = PageController();

  String? _speciality;
  String? _modality;
  final TextEditingController _bioController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    _auth = widget.auth ?? FirebaseAuth.instance;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _goTo(int step) async {
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _saveProfileAndAdvance() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    if (_speciality == null || _modality == null) return;

    setState(() => _saving = true);
    try {
      await _firestore.collection('users').doc(uid).update({
        'speciality': _speciality,
        'modality': _modality,
        if (_bioController.text.trim().isNotEmpty)
          'bio': _bioController.text.trim(),
      });
      if (!mounted) return;
      await _goTo(2);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _finish() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await _firestore.collection('users').doc(uid).update({
        'onboardingCompleted': true,
      });
      AppRouter.markUserOnboardingCompleted();
      if (!mounted) return;
      context.go('/therapist');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildWelcomeStep(),
            _buildProfileStep(),
            _buildLicenseStep(),
            _buildDoneStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          const Icon(LucideIcons.heartPulse, size: 96, color: Color(0xFF2563EB)),
          const SizedBox(height: 32),
          Text(
            '¡Bienvenido a RehabTech!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          const Text(
            'La plataforma que conecta fisioterapeutas con sus pacientes.',
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => _goTo(1),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Comenzar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep() {
    final canContinue =
        !_saving && _speciality != null && _modality != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Completa tu perfil',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            const Text('Tus pacientes verán esta información'),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              key: const Key('therapist-onboarding-speciality'),
              initialValue: _speciality,
              decoration: const InputDecoration(
                labelText: 'Especialidad',
                border: OutlineInputBorder(),
              ),
              items: _kSpecialities
                  .map((s) =>
                      DropdownMenuItem<String>(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _speciality = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio profesional (opcional)',
                border: OutlineInputBorder(),
                helperText: 'Hasta 300 caracteres',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const Key('therapist-onboarding-modality'),
              initialValue: _modality,
              decoration: const InputDecoration(
                labelText: 'Modalidad',
                border: OutlineInputBorder(),
              ),
              items: _kModalities
                  .map((s) =>
                      DropdownMenuItem<String>(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _modality = v),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: canContinue ? _saveProfileAndAdvance : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const Icon(LucideIcons.shieldCheck,
              size: 80, color: Color(0xFF2563EB)),
          const SizedBox(height: 24),
          Text(
            'Verifica tu cédula',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tus pacientes podrán ver que eres un profesional certificado '
            'por la SEP. El proceso toma menos de 1 minuto.',
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => context.go('/license-verification'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Verificar ahora'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _goTo(3),
            child: const Text('Verificar después'),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (_, scale, _) => Transform.scale(
              scale: scale,
              child: const Icon(
                Icons.check_circle,
                size: 120,
                color: Color(0xFF22C55E),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '¡Todo listo!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Puedes verificar tu cédula en cualquier momento desde tu perfil. '
            'Los pacientes verán un aviso hasta que la verifiques.',
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(
            onPressed: _saving ? null : _finish,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Ir a mi panel'),
          ),
        ],
      ),
    );
  }
}
