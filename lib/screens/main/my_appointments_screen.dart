import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../presentation/widgets/common/app_gradient_background.dart';

/// Read-only viewer for appointments scheduled by the patient's therapist.
///
/// Subscribes to `appointments/` filtered by `patientId == currentUser.uid`,
/// ordered by `dateTime` ascending. Renders two sections: upcoming and past.
class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: user == null
              ? const Center(child: Text('Inicia sesión para ver tus citas'))
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('appointments')
                      .where('patientId', isEqualTo: user.uid)
                      .orderBy('dateTime')
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return _ErrorState(message: '${snap.error}');
                    }

                    final now = DateTime.now();
                    final docs = snap.data?.docs ?? const [];
                    final upcoming = <_AppointmentView>[];
                    final past = <_AppointmentView>[];
                    for (final d in docs) {
                      final view = _AppointmentView.fromMap(d.data());
                      if (view.dateTime.isAfter(now)) {
                        upcoming.add(view);
                      } else {
                        past.add(view);
                      }
                    }
                    // Past viene cronologicamente; queremos lo más reciente arriba.
                    final pastDescending = past.reversed.toList();

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _Header(colorScheme: colorScheme)),
                        if (docs.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyState(colorScheme: colorScheme),
                          )
                        else ...[
                          if (upcoming.isNotEmpty)
                            _AppointmentSection(
                              title: 'Próximas',
                              items: upcoming,
                              highlight: true,
                            ),
                          if (pastDescending.isNotEmpty)
                            _AppointmentSection(
                              title: 'Pasadas',
                              items: pastDescending,
                              highlight: false,
                            ),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _AppointmentView {
  const _AppointmentView({
    required this.dateTime,
    required this.sessionType,
    required this.status,
  });

  factory _AppointmentView.fromMap(Map<String, dynamic> data) {
    final ts = data['dateTime'];
    return _AppointmentView(
      dateTime: ts is Timestamp ? ts.toDate() : DateTime.now(),
      sessionType: (data['sessionType'] as String?) ?? 'Sesión',
      status: (data['status'] as String?) ?? 'scheduled',
    );
  }

  final DateTime dateTime;
  final String sessionType;
  final String status;
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

class _AppointmentSection extends StatelessWidget {
  const _AppointmentSection({
    required this.title,
    required this.items,
    required this.highlight,
  });

  final String title;
  final List<_AppointmentView> items;
  final bool highlight;

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
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AppointmentCard(view: it, highlight: highlight),
            ),
        ]),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.view, required this.highlight});
  final _AppointmentView view;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = highlight ? const Color(0xFF2563EB) : colorScheme.onSurfaceVariant;
    final dateFmt = DateFormat("EEEE d 'de' MMM", 'es_ES').format(view.dateTime);
    final timeFmt = DateFormat('HH:mm').format(view.dateTime);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themedGlassColor(context, alpha: highlight ? 0.85 : 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? const Color(0xFF2563EB).withValues(alpha: 0.25)
              : themedGlassBorder(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.calendar, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  view.sessionType,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dateFmt[0].toUpperCase()}${dateFmt.substring(1)} · $timeFmt',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _StatusChip(status: view.status),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'scheduled' => ('Agendada', const Color(0xFF2563EB)),
      'completed' => ('Completada', const Color(0xFF10B981)),
      'cancelled' => ('Cancelada', const Color(0xFFEF4444)),
      _ => (status, Theme.of(context).colorScheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.calendar, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Sin citas agendadas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando tu terapeuta agende una cita contigo, '
              'aparecerá aquí con la fecha y hora.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
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
            const Icon(LucideIcons.circleAlert, size: 48, color: Color(0xFFEF4444)),
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
