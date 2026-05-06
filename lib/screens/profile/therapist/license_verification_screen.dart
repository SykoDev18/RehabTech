import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehabtech/core/utils/url_launcher_helper.dart';
import 'package:rehabtech/domain/entities/therapist_license_entity.dart';
import 'package:rehabtech/services/license_verification_service.dart';

const _maxAttemptsPerDay = 3;
const _specialityOptions = <String>[
  'Fisioterapia',
  'Rehabilitación Física',
  'Kinesiología',
  'Terapia Física',
  'Terapia Ocupacional',
  'Otra',
];

/// Full-screen flow for a therapist to enter and verify their cédula
/// profesional against the SEP RNP. The screen never directly hits SEP — the
/// underlying [LicenseVerificationService] routes through the
/// `verifyProfessionalLicense` Cloud Function.
class LicenseVerificationScreen extends StatefulWidget {
  final LicenseVerificationService? service;

  const LicenseVerificationScreen({super.key, this.service});

  @override
  State<LicenseVerificationScreen> createState() =>
      _LicenseVerificationScreenState();
}

class _LicenseVerificationScreenState extends State<LicenseVerificationScreen> {
  late final LicenseVerificationService _service;
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();

  String? _speciality;
  bool _isLoading = false;
  LicenseVerificationResult? _result;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? LicenseVerificationService();
  }

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final speciality = _speciality;
    if (speciality == null) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _result = null;
    });

    final result = await _service.verify(
      licenseNumber: _licenseController.text.trim(),
      speciality: speciality,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _result = result;
    });
  }

  Future<void> _openSepSite() async {
    await UrlLauncherHelper.launchLink(
      context: context,
      url: 'https://cedulaprofesional.sep.gob.mx',
      label: 'Cédula Profesional SEP',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para continuar.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de cédula'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: StreamBuilder<TherapistLicense>(
        stream: _service.watchLicense(user.uid),
        builder: (context, snapshot) {
          final license = snapshot.data ?? const TherapistLicense();
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusBanner(license),
                  const SizedBox(height: 16),
                  if (_canShowForm(license))
                    _buildForm(license)
                  else
                    const SizedBox.shrink(),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _result == null
                        ? const SizedBox.shrink(key: ValueKey('no-result'))
                        : _buildResultCard(_result!),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _canShowForm(TherapistLicense license) {
    return license.status == LicenseStatus.unverified ||
        license.status == LicenseStatus.rejected;
  }

  // ────────────────────────── Section A ──────────────────────────

  Widget _buildStatusBanner(TherapistLicense license) {
    // While the user is mid-call, force the pending state — the Firestore doc
    // doesn't actually flip to "pending" because the rules forbid client writes
    // to that field. We render the same UI either way.
    if (_isLoading) return _pendingBanner();

    return switch (license.status) {
      LicenseStatus.verified => _verifiedBanner(license),
      LicenseStatus.pending => _pendingBanner(),
      LicenseStatus.manualReview => _manualReviewBanner(
          license.verificationError ??
              'Tu cédula está en revisión manual. Te avisaremos en 1-3 días hábiles.',
        ),
      LicenseStatus.rejected => _rejectedBanner(
          license.verificationError ?? 'No se pudo verificar tu cédula.',
        ),
      LicenseStatus.unverified => _unverifiedBanner(),
    };
  }

  Widget _verifiedBanner(TherapistLicense license) {
    final data = license.licenseData;
    final dateText = license.verifiedAt != null
        ? DateFormat('dd/MM/yyyy').format(license.verifiedAt!)
        : '';
    return _bannerCard(
      color: const Color(0xFF22C55E),
      background: const Color(0xFFE8F5E9),
      icon: LucideIcons.badgeCheck,
      title: 'Cédula verificada',
      lines: [
        if (data != null) '${data.fullName}  ·  ${data.titulo}',
        if (dateText.isNotEmpty) 'Verificada el $dateText',
      ],
    );
  }

  Widget _pendingBanner() {
    return _bannerCard(
      color: const Color(0xFF3B82F6),
      background: const Color(0xFFE3F2FD),
      icon: LucideIcons.loader,
      title: 'Verificando tu cédula...',
      lines: const ['Consultando el RNP de la SEP'],
      footer: const LinearProgressIndicator(),
    );
  }

  Widget _manualReviewBanner(String reason) {
    return _bannerCard(
      color: const Color(0xFFF59E0B),
      background: const Color(0xFFFFF8E1),
      icon: LucideIcons.triangleAlert,
      title: 'Tu cédula requiere revisión manual',
      lines: [
        reason,
        'Nuestro equipo la revisará en 1-3 días hábiles. '
            'Puedes seguir usando la app normalmente.',
      ],
    );
  }

  Widget _rejectedBanner(String error) {
    return _bannerCard(
      color: const Color(0xFFEF4444),
      background: const Color(0xFFFEE2E2),
      icon: LucideIcons.circleAlert,
      title: 'No se pudo verificar',
      lines: [error, 'Puedes intentarlo de nuevo abajo.'],
    );
  }

  Widget _unverifiedBanner() {
    return _bannerCard(
      color: const Color(0xFF3B82F6),
      background: const Color(0xFFE3F2FD),
      icon: LucideIcons.shieldCheck,
      title: 'Verifica tu cédula profesional',
      lines: const [
        'Tus pacientes verán un sello de verificación una vez confirmada en el '
            'Registro Nacional de Profesionistas de la SEP.',
      ],
    );
  }

  Widget _bannerCard({
    required Color color,
    required Color background,
    required IconData icon,
    required String title,
    required List<String> lines,
    Widget? footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                ...lines.map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      l,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: 8),
                  footer,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────── Section B ──────────────────────────

  Widget _buildForm(TherapistLicense license) {
    final attemptsLeft = (_maxAttemptsPerDay - license.verificationAttempts)
        .clamp(0, _maxAttemptsPerDay);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Verificamos tu cédula directamente en el Registro Nacional '
            'de Profesionistas de la SEP.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _licenseController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 8,
            enabled: !_isLoading,
            decoration: const InputDecoration(
              labelText: 'Número de cédula profesional',
              helperText: 'El número de 7-8 dígitos impreso en tu cédula',
              border: OutlineInputBorder(),
              prefixIcon: Icon(LucideIcons.idCard),
            ),
            validator: (value) =>
                _service.validateFormat(value ?? ''),
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _speciality ?? license.speciality,
            decoration: const InputDecoration(
              labelText: 'Especialidad',
              border: OutlineInputBorder(),
              prefixIcon: Icon(LucideIcons.stethoscope),
            ),
            items: _specialityOptions
                .map(
                  (s) => DropdownMenuItem<String>(value: s, child: Text(s)),
                )
                .toList(),
            onChanged: _isLoading
                ? null
                : (v) => setState(() => _speciality = v),
            validator: (v) =>
                v == null || v.isEmpty ? 'Selecciona tu especialidad' : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ||
                    license.status == LicenseStatus.verified ||
                    attemptsLeft == 0
                ? null
                : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Consultando SEP...'),
                    ],
                  )
                : const Text(
                    'Verificar cédula',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(height: 8),
          const Text(
            '⏱ Este proceso puede tomar 10-15 segundos.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          Text(
            'Tienes $attemptsLeft intentos restantes hoy.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  // ────────────────────────── Section C ──────────────────────────

  Widget _buildResultCard(LicenseVerificationResult result) {
    return switch (result) {
      LicenseVerified() => _buildVerifiedResult(result),
      LicenseNotFound() ||
      LicenseInvalidInput() =>
        _buildErrorResult(result, key: const ValueKey('error-result')),
      LicenseManualReview() => _bannerCard(
          color: const Color(0xFFF59E0B),
          background: const Color(0xFFFFF8E1),
          icon: LucideIcons.triangleAlert,
          title: 'En revisión manual',
          lines: [result.message],
        ),
      LicenseRateLimited() => _bannerCard(
          color: const Color(0xFFEF4444),
          background: const Color(0xFFFEE2E2),
          icon: LucideIcons.clock,
          title: 'Límite de intentos',
          lines: [result.message],
        ),
      LicenseVerificationError() => _bannerCard(
          color: const Color(0xFFEF4444),
          background: const Color(0xFFFEE2E2),
          icon: LucideIcons.circleAlert,
          title: 'Error',
          lines: [result.message],
        ),
    };
  }

  Widget _buildVerifiedResult(LicenseVerified result) {
    final d = result.data;
    return Card(
      key: const ValueKey('verified-result'),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.badgeCheck,
                    color: Color(0xFF22C55E), size: 22),
                SizedBox(width: 8),
                Text(
                  'Cédula verificada',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Datos del Registro Nacional de Profesionistas',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const Divider(height: 24),
            _kv('Nombre', d.fullName),
            _kv('Profesión', d.titulo),
            _kv('Institución', d.institucion),
            _kv('Expedida', d.fechaExpedicion),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorResult(
    LicenseVerificationResult result, {
    required Key key,
  }) {
    return Card(
      key: key,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No se encontró la cédula',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 8),
            Text(result.message),
            const SizedBox(height: 12),
            const Text(
              '¿El número es correcto? Puedes verificarlo en '
              'cedulaprofesional.sep.gob.mx',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _openSepSite,
              icon: const Icon(LucideIcons.externalLink, size: 16),
              label: const Text('Abrir sitio de la SEP'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Helper: bottom-sheet shown when a patient taps a verified badge.
// Lives here next to the screen so the badge can stay presentation-only.
// ─────────────────────────────────────────────────────────────────────

void showVerifiedTherapistSheet(
  BuildContext context, {
  required String therapistName,
  required String? licenseNumber,
  required LicenseData? licenseData,
  required DateTime? verifiedAt,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final dateText = verifiedAt != null
          ? DateFormat('dd/MM/yyyy').format(verifiedAt)
          : '';
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.badgeCheck,
                    color: Color(0xFF22C55E), size: 28),
                SizedBox(width: 8),
                Text(
                  'Terapeuta verificado por la SEP',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'La cédula de $therapistName fue validada en el Registro '
              'Nacional de Profesionistas de la Secretaría de Educación '
              'Pública.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (licenseNumber != null && licenseNumber.isNotEmpty)
              _sheetRow('Cédula', licenseNumber),
            if (licenseData?.titulo.isNotEmpty ?? false)
              _sheetRow('Profesión', licenseData!.titulo),
            if (dateText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Verificada el $dateText',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

Widget _sheetRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

// Suppress unused-import warnings if these helpers are imported elsewhere
// without referencing the Cloud Firestore Timestamp directly.
// ignore: unused_element
DateTime? _toDate(Object? raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  return null;
}
