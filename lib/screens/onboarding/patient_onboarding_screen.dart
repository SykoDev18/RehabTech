import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:rehabtech/router/app_router.dart';

/// Four-step welcome flow for newly registered patients.
class PatientOnboardingScreen extends StatefulWidget {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;

  const PatientOnboardingScreen({super.key, this.firestore, this.auth});

  @override
  State<PatientOnboardingScreen> createState() =>
      _PatientOnboardingScreenState();
}

class _PatientOnboardingScreenState extends State<PatientOnboardingScreen> {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  final PageController _pageController = PageController();

  DateTime? _dob;
  final TextEditingController _condition = TextEditingController();
  final TextEditingController _emergencyName = TextEditingController();
  final TextEditingController _emergencyPhone = TextEditingController();
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
    _condition.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  Future<void> _goTo(int step) async {
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _saveProfileAndAdvance({required bool skip}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final updates = <String, dynamic>{};
      if (!skip) {
        if (_dob != null) updates['dob'] = Timestamp.fromDate(_dob!);
        if (_condition.text.trim().isNotEmpty) {
          updates['condition'] = _condition.text.trim();
        }
        if (_emergencyName.text.trim().isNotEmpty) {
          updates['emergencyContactName'] = _emergencyName.text.trim();
        }
        if (_emergencyPhone.text.trim().isNotEmpty) {
          updates['emergencyContactPhone'] = _emergencyPhone.text.trim();
        }
      }
      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
      }
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
      context.go('/main');
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
            _buildWelcome(),
            _buildProfile(),
            _buildHowItWorks(),
            _buildDone(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          const Icon(LucideIcons.heartPulse,
              size: 96, color: Color(0xFF2563EB)),
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
            'Tu compañero en la rehabilitación física.',
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

  Widget _buildProfile() {
    final dobLabel = _dob == null
        ? 'Selecciona tu fecha de nacimiento'
        : DateFormat('dd/MM/yyyy').format(_dob!);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Cuéntanos un poco',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            const Text('Tu terapeuta verá esta información (todo es opcional)'),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickDob,
              icon: const Icon(LucideIcons.calendar),
              label: Text(dobLabel),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _condition,
              maxLength: 200,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Condición o motivo de rehabilitación',
                hintText: 'Ej. Lesión de rodilla, dolor lumbar...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emergencyName,
              decoration: const InputDecoration(
                labelText: 'Contacto de emergencia — nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emergencyPhone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Contacto de emergencia — teléfono',
                helperText: '10 dígitos',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () => _saveProfileAndAdvance(skip: false),
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
            TextButton(
              onPressed: _saving
                  ? null
                  : () => _saveProfileAndAdvance(skip: true),
              child: const Text('Omitir por ahora'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            '¿Cómo funciona RehabTech?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 24),
          _featureCard(
            icon: LucideIcons.dumbbell,
            title: 'Tus rutinas',
            body: 'Tu terapeuta te asignará ejercicios personalizados.',
          ),
          const SizedBox(height: 12),
          _featureCard(
            icon: LucideIcons.sparkles,
            title: 'Nora, tu asistente',
            body: 'Pregúntale a Nora sobre tus ejercicios y dolor.',
          ),
          const SizedBox(height: 12),
          _featureCard(
            icon: LucideIcons.calendar,
            title: 'Tus citas',
            body: 'Agenda y gestiona tus citas directamente en la app.',
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => _goTo(3),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: const Color(0xFF2563EB)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDone() {
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
            '¡Listo para comenzar!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
