import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../domain/entities/patient_entity.dart';

class PatientDetailScreen extends StatelessWidget {
  final PatientEntity patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDBEAFE),
              Color(0xFFF0FDF4),
              Color(0xFFEFF6FF),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF111827)),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.ellipsisVertical, color: Color(0xFF111827)),
                  onPressed: () {},
                ),
              ],
            ),
            // Profile header
            SliverToBoxAdapter(
              child: _buildProfileHeader(),
            ),
            // Info cards
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildProgressCard(),
                  const SizedBox(height: 16),
                  _buildSessionsCard(),
                  const SizedBox(height: 16),
                  _LivePainHistoryCard(patientId: patient.id),
                  const SizedBox(height: 16),
                  _LiveRoutinesCard(patientId: patient.id),
                  const SizedBox(height: 16),
                  _LiveAppointmentsCard(patientId: patient.id),
                  const SizedBox(height: 16),
                  _buildQuestionsCard(),
                  const SizedBox(height: 16),
                  _buildNotesCard(),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Center(
              child: Text(
                patient.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            patient.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            patient.condition,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: patient.needsAttention
                  ? const Color(0xFFF97316)
                  : const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              patient.statusLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Personal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          if (patient.age != null)
            _InfoRow(icon: LucideIcons.calendar, label: 'Edad', value: '${patient.age} años'),
          if (patient.phone != null)
            _InfoRow(icon: LucideIcons.phone, label: 'Teléfono', value: patient.phone!),
          _InfoRow(icon: LucideIcons.mail, label: 'Email', value: patient.email),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.trendingUp, color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Progreso del Tratamiento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: patient.progressPercentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${patient.progressPercentage.toStringAsFixed(0)}% completado',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.clock, color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Sesiones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  value: '${patient.completedSessions}',
                  label: 'Completadas',
                  color: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  value: '${patient.totalSessions - patient.completedSessions}',
                  label: 'Pendientes',
                  color: const Color(0xFFF97316),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.messageSquareMore, color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Dudas del Paciente',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              if (patient.pendingQuestions > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${patient.pendingQuestions} pendientes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            patient.pendingQuestions > 0
                ? 'Hay preguntas que necesitan respuesta'
                : 'No hay dudas pendientes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notas Clínicas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Icon(LucideIcons.pencil, color: Colors.grey[400], size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            patient.notes ?? 'Sin notas aún. Toca para agregar notas sobre el paciente.',
            style: TextStyle(
              fontSize: 14,
              color: patient.notes != null ? const Color(0xFF111827) : Colors.grey[500],
              fontStyle: patient.notes == null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Streams las sesiones del paciente desde users/{patientId}/progress y
/// muestra agregados (totales 7d/30d, promedio de dolor, ultima actividad)
/// + las ultimas 5 sesiones detalladas. Esta es la unica forma con la que
/// el terapeuta ve la evolucion REAL del paciente — el resto de los cards
/// muestran stats que el terapeuta controla manualmente en PatientEntity.
class _LivePainHistoryCard extends StatelessWidget {
  const _LivePainHistoryCard({required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .collection('progress')
          .orderBy('date', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snap) {
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.activity, color: Color(0xFFEF4444), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Historial de dolor y sesiones',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ))
              else if (snap.hasError)
                Text(
                  'No se pudo cargar el historial: ${snap.error}',
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                )
              else
                _buildContent(snap.data?.docs ?? const []),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return Text(
        'Aún no hay sesiones registradas. Cuando el paciente complete '
        'ejercicios, su historial aparecerá aquí.',
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      );
    }

    final now = DateTime.now();
    final cutoff7d = now.subtract(const Duration(days: 7));
    final cutoff30d = now.subtract(const Duration(days: 30));

    int sessions7d = 0;
    int sessions30d = 0;
    double painSum7d = 0;
    int painCount7d = 0;
    DateTime? lastActivity;

    for (final d in docs) {
      final data = d.data();
      final ts = data['date'];
      final date = ts is Timestamp ? ts.toDate() : null;
      if (date == null) continue;
      lastActivity ??= date; // primero (mas reciente por ordenamiento desc)
      if (date.isAfter(cutoff7d)) {
        sessions7d++;
        final pain = (data['painLevel'] as num?)?.toDouble();
        if (pain != null) {
          painSum7d += pain;
          painCount7d++;
        }
      }
      if (date.isAfter(cutoff30d)) sessions30d++;
    }
    final avgPain7d = painCount7d == 0 ? null : painSum7d / painCount7d;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatBox(
                value: '$sessions7d',
                label: 'Últimos 7 días',
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatBox(
                value: '$sessions30d',
                label: 'Últimos 30 días',
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatBox(
                value: avgPain7d == null ? '—' : avgPain7d.toStringAsFixed(1),
                label: 'Dolor 7d',
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (lastActivity != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Última actividad: ${DateFormat("d 'de' MMM HH:mm", 'es_ES').format(lastActivity)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        const Text(
          'Últimas sesiones',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        for (final d in docs.take(5)) _SessionRow(data: d.data()),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final exerciseName = (data['exerciseName'] as String?) ?? 'Ejercicio';
    final pain = (data['painLevel'] as num?)?.toInt() ?? 0;
    final completion = (data['completionPercentage'] as num?)?.toDouble() ?? 0;
    final ts = data['date'];
    final date = ts is Timestamp ? ts.toDate() : null;
    final dateLabel = date == null
        ? '—'
        : DateFormat('d/M HH:mm').format(date);

    final painColor = pain <= 3
        ? const Color(0xFF22C55E)
        : pain <= 6
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: painColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              exerciseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
            ),
          ),
          Text(
            '$dateLabel · ${completion.toStringAsFixed(0)}% · dolor $pain',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

/// Lista las rutinas asignadas al paciente para que el terapeuta vea de un
/// vistazo qué le tiene programado y cuántos ejercicios contiene cada una.
class _LiveRoutinesCard extends StatelessWidget {
  const _LiveRoutinesCard({required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('routines')
          .where('patientId', isEqualTo: patientId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.dumbbell, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Rutinas asignadas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ))
              else if (snap.hasError)
                Text(
                  'Error: ${snap.error}',
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                )
              else if ((snap.data?.docs ?? const []).isEmpty)
                Text(
                  'Sin rutinas asignadas a este paciente.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                )
              else
                Column(
                  children: [
                    for (final d in snap.data!.docs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.chevronRight,
                                size: 16, color: Color(0xFF6B7280)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                (d.data()['name'] as String?) ?? 'Rutina',
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF111827)),
                              ),
                            ),
                            Text(
                              '${(d.data()['exercises'] as List?)?.length ?? 0} ejercicios',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Próxima cita del paciente, leído de la colección global appointments.
class _LiveAppointmentsCard extends StatelessWidget {
  const _LiveAppointmentsCard({required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('dateTime')
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.calendar, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Próximas citas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ))
              else if (snap.hasError)
                Text(
                  'Error: ${snap.error}',
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                )
              else if ((snap.data?.docs ?? const []).isEmpty)
                Text(
                  'Sin citas próximas.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                )
              else
                Column(
                  children: [
                    for (final d in snap.data!.docs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _UpcomingApt(data: d.data()),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _UpcomingApt extends StatelessWidget {
  const _UpcomingApt({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final ts = data['dateTime'];
    final date = ts is Timestamp ? ts.toDate() : null;
    final type = (data['sessionType'] as String?) ?? 'Sesión';
    final dateLabel = date == null
        ? '—'
        : DateFormat("EEEE d 'de' MMM HH:mm", 'es_ES').format(date);
    return Row(
      children: [
        const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            type,
            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          ),
        ),
        Text(
          dateLabel,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
