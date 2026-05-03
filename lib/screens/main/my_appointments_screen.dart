import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/repositories/firestore_appointment_repository.dart';
import '../../domain/models/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../presentation/widgets/common/app_gradient_background.dart';
import '../../screens/appointments/book_appointment_sheet.dart';
import '../../widgets/appointments/appointment_list_tile.dart';

/// Patient list of all their appointments — both legacy therapist-created
/// (`status: 'scheduled'`, no `type`) and new patient-booked. Items split
/// into "Próximas" / "Pasadas" sections by [Appointment.isUpcoming].
///
/// Tap an item → `/main/my-appointments/:id` (detail). Empty state shows
/// the booking shortcut, but it requires the patient to know their
/// therapistId; if there's no link, we surface a friendlier message
/// pointing them at "Mi terapeuta".
class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final AppointmentRepository _repo = FirestoreAppointmentRepository();
  // Cache therapist names so list rebuilds don't refetch per tile. Empty
  // string sentinel means "looked up, missing" so we don't loop.
  final Map<String, String> _therapistNameCache = {};

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: user == null
              ? const Center(child: Text('Inicia sesión para ver tus citas'))
              : StreamBuilder<List<Appointment>>(
                  stream: _repo.watchPatientAppointments(user.uid),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return _ErrorState(message: '${snap.error}');
                    }

                    final all = snap.data ?? const <Appointment>[];
                    final upcoming =
                        all.where((a) => a.isUpcoming).toList();
                    final past = all
                        .where((a) => !a.isUpcoming)
                        .toList()
                        .reversed
                        .toList();

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _Header(colorScheme: colorScheme),
                        ),
                        if (all.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyState(
                              colorScheme: colorScheme,
                              patientUid: user.uid,
                            ),
                          )
                        else ...[
                          if (upcoming.isNotEmpty)
                            _Section(
                              title: 'Próximas',
                              items: upcoming,
                              resolveOtherParty: _therapistName,
                            ),
                          if (past.isNotEmpty)
                            _Section(
                              title: 'Pasadas',
                              items: past,
                              resolveOtherParty: _therapistName,
                            ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 24),
                          ),
                        ],
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  /// Returns the therapist's display name. Caches the result so a list of
  /// 30 appointments with the same therapist results in a single read.
  Future<String> _therapistName(String therapistId) async {
    final cached = _therapistNameCache[therapistId];
    if (cached != null) return cached;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(therapistId)
          .get();
      final data = doc.data() ?? const <String, dynamic>{};
      final name = '${data['name'] ?? ''} ${data['lastName'] ?? ''}'.trim();
      _therapistNameCache[therapistId] = name;
      return name;
    } catch (_) {
      _therapistNameCache[therapistId] = '';
      return '';
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themedGlassColor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.arrowLeft,
                size: 22,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Mis Citas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.resolveOtherParty,
  });

  final String title;
  final List<Appointment> items;
  final Future<String> Function(String otherPartyId) resolveOtherParty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final a in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FutureBuilder<String>(
                future: resolveOtherParty(a.therapistId),
                builder: (context, snap) {
                  return AppointmentListTile(
                    appointment: a,
                    otherPartyName: snap.data ?? 'Tu terapeuta',
                    onTap: () =>
                        context.go('/main/my-appointments/${a.id}'),
                  );
                },
              ),
            ),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.colorScheme,
    required this.patientUid,
  });
  final ColorScheme colorScheme;
  final String patientUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(patientUid)
          .snapshots(),
      builder: (context, snap) {
        final therapistId =
            (snap.data?.data()?['therapistId'] as String?) ?? '';
        final hasTherapist = therapistId.isNotEmpty;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 64,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sin citas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasTherapist
                      ? 'Agenda tu primera cita con tu terapeuta.'
                      : 'Conecta con un terapeuta antes de agendar tu primera cita.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                if (hasTherapist)
                  ElevatedButton.icon(
                    onPressed: () => BookAppointmentSheet.show(
                      context,
                      patientId: patientUid,
                      therapistId: therapistId,
                    ),
                    icon: const Icon(LucideIcons.calendarPlus),
                    label: const Text('Agendar Cita'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => context.go('/profile/therapist'),
                    icon: const Icon(LucideIcons.user),
                    label: const Text('Ver mi terapeuta'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.circleAlert,
                size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar las citas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
