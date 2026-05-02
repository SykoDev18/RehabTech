import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehabtech/router/app_router.dart';
import 'package:rehabtech/widgets/patient_therapist_badge.dart';
import 'package:url_launcher/url_launcher.dart';

/// Patient-facing "my therapist" screen.
///
/// All data comes from Firestore (no SharedPreferences fallback): the
/// currently-signed-in patient's `users/{uid}.therapistId` resolves to the
/// therapist's user doc, and the next upcoming appointment is queried from
/// `appointments`. Hardcoded contact info has been removed — when a field is
/// missing from Firestore the screen shows "—" rather than a placeholder.
class MyTherapistScreen extends StatelessWidget {
  const MyTherapistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.green[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: uid == null
                    ? const Center(
                        child: Text('Inicia sesión para ver a tu terapeuta'),
                      )
                    : _PatientWatcher(uid: uid),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.arrowLeft, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Mi Terapeuta',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

/// Watches the patient's user doc to extract `therapistId`. Routes to either
/// [_TherapistInfo] or [_NoTherapistState] based on what's there.
class _PatientWatcher extends StatelessWidget {
  const _PatientWatcher({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No se pudo cargar tu información: ${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        final therapistId = snap.data?.data()?['therapistId'] as String?;
        if (therapistId == null || therapistId.isEmpty) {
          return const _NoTherapistState();
        }
        return _TherapistInfo(patientUid: uid, therapistId: therapistId);
      },
    );
  }
}

class _TherapistInfo extends StatelessWidget {
  const _TherapistInfo({
    required this.patientUid,
    required this.therapistId,
  });

  final String patientUid;
  final String therapistId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(therapistId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No se pudo cargar al terapeuta: ${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final data = snap.data?.data() ?? const <String, dynamic>{};
        final firstName = (data['name'] as String?) ?? '';
        final lastName = (data['lastName'] as String?) ?? '';
        final fullName = '$firstName $lastName'.trim();
        final displayName = fullName.isEmpty ? 'Terapeuta' : fullName;
        final email = (data['email'] as String?) ?? '';
        final phone = (data['phone'] as String?) ?? '';
        final address = (data['address'] as String?) ?? '';
        final specialty =
            (data['specialty'] as String?)?.trim().isNotEmpty == true
                ? data['specialty'] as String
                : 'Fisioterapeuta';
        final photoUrl = (data['photoUrl'] as String?) ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildTherapistCard(
                context,
                displayName: displayName,
                specialty: specialty,
                email: email,
                phone: phone,
                address: address,
                photoUrl: photoUrl,
              ),
              const SizedBox(height: 24),
              _buildActionButtons(context, phone: phone),
              const SizedBox(height: 24),
              _NextAppointmentCard(
                patientUid: patientUid,
                therapistId: therapistId,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTherapistCard(
    BuildContext context, {
    required String displayName,
    required String specialty,
    required String email,
    required String phone,
    required String address,
    required String photoUrl,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  shape: BoxShape.circle,
                  image: photoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(photoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: photoUrl.isEmpty
                    ? const Icon(
                        LucideIcons.stethoscope,
                        size: 45,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              PatientTherapistBadge(therapistName: displayName),
              const SizedBox(height: 4),
              Text(
                specialty,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              _buildContactRow(LucideIcons.mail, 'Correo', email),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildContactRow(LucideIcons.phone, 'Teléfono', phone),
              ],
              if (address.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildContactRow(LucideIcons.mapPin, 'Ubicación', address),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              Text(
                value.isEmpty ? '—' : value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, {required String phone}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: LucideIcons.phone,
                label: 'Llamar',
                color: const Color(0xFF22C55E),
                enabled: phone.isNotEmpty,
                onTap: phone.isEmpty
                    ? null
                    : () => _launchPhone(context, phone: phone),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: LucideIcons.messageCircle,
                label: 'Mensaje',
                color: const Color(0xFF3B82F6),
                onTap: () => context.goToTherapistChat(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: LucideIcons.video,
                label: 'Videollamada',
                color: const Color(0xFF8B5CF6),
                enabled: false,
                comingSoon: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: LucideIcons.calendar,
                label: 'Agendar Cita',
                color: const Color(0xFFF59E0B),
                enabled: false,
                comingSoon: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _launchPhone(BuildContext context, {required String phone}) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede realizar la llamada')),
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.enabled = true,
    this.comingSoon = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final dimColor = color.withValues(alpha: enabled ? 1.0 : 0.4);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.65,
          child: GestureDetector(
            onTap: enabled
                ? onTap
                : comingSoon
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Próximamente disponible'),
                          ),
                        )
                    : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(icon, color: dimColor, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dimColor,
                    ),
                  ),
                  if (comingSoon)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Próximamente',
                        style: TextStyle(
                          fontSize: 10,
                          color: dimColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Streams the patient's next upcoming appointment. The patient↔therapist
/// link is 1:1, so filtering by `patientId` alone is sufficient — the
/// existing composite index `(patientId, dateTime ASC)` covers the query.
class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({
    required this.patientUid,
    required this.therapistId,
  });

  final String patientUid;
  final String therapistId;

  @override
  Widget build(BuildContext context) {
    final now = Timestamp.fromDate(DateTime.now());
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: patientUid)
          .where('dateTime', isGreaterThanOrEqualTo: now)
          .orderBy('dateTime')
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _AppointmentCardShell(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          );
        }
        if (snap.hasError || (snap.data?.docs.isEmpty ?? true)) {
          return _AppointmentCardShell(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B7280).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.calendarOff,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próxima Cita',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sin citas próximas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snap.data!.docs.first.data();
        final ts = data['dateTime'];
        final dt = ts is Timestamp ? ts.toDate() : null;
        final sessionType =
            (data['sessionType'] as String?) ?? 'Sesión';

        return GestureDetector(
          onTap: () => context.goToMyAppointments(),
          child: _AppointmentCardShell(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (dt != null) _DateBadge(dateTime: dt),
                  if (dt != null) const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Próxima Cita',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sessionType,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (dt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatTimeRange(dt),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTimeRange(DateTime start) {
    final end = start.add(const Duration(hours: 1));
    String fmt(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${fmt(start)} - ${fmt(end)}';
  }
}

class _AppointmentCardShell extends StatelessWidget {
  const _AppointmentCardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.dateTime});
  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    const months = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            dateTime.day.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            months[dateTime.month - 1],
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _NoTherapistState extends StatelessWidget {
  const _NoTherapistState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.userPlus,
                      size: 48,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sin Terapeuta Asignado',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Comparte tu ID de paciente con un terapeuta para que '
                    'pueda asignarte como su paciente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final mailUri = Uri.parse(
                        'mailto:rehabtechnoreply@gmail.com'
                        '?subject=Necesito%20un%20terapeuta',
                      );
                      if (await canLaunchUrl(mailUri)) {
                        await launchUrl(mailUri);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No se pudo abrir el correo'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(LucideIcons.mail, color: Colors.white),
                    label: const Text(
                      'Contactar Soporte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
