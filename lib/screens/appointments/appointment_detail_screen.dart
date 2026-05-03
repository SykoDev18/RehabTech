import 'package:add_2_calendar/add_2_calendar.dart' as cal;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/repositories/firestore_appointment_repository.dart';
import '../../domain/exceptions/appointment_exception.dart';
import '../../domain/models/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../widgets/appointments/appointment_status_chip.dart';
import '../../widgets/appointments/appointment_type_chip.dart';
import 'reschedule_appointment_sheet.dart';

/// Detail screen for a single appointment.
///
/// Role is inferred from the current Firebase user matching either the
/// appointment's `therapistId` or `patientId`. The action set rotates with
/// status:
///
///  Patient | pending   → cancelar solicitud
///          | confirmed → cancelar + agregar al calendario
///          | cancelled → banner "Cita cancelada"
///          | completed → "Calificar sesión" (Próximamente)
///
///  Therapist | pending   → confirmar / rechazar
///            | confirmed → marcar completada / reprogramar
///            | completed → editar notas
///            | cancelled → banner "Cita cancelada"
///
/// The screen subscribes to the doc so it reacts live (e.g. patient sees the
/// "Pendiente" banner flip to "Confirmada" as soon as the therapist accepts).
class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final AppointmentRepository _repo = FirestoreAppointmentRepository();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de cita'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => _safePop(context),
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Inicia sesión para ver tu cita'))
          : StreamBuilder<Appointment?>(
              stream: _repo.watchAppointment(widget.appointmentId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final appt = snap.data;
                if (appt == null) {
                  return const _NotFound();
                }
                final isTherapist = appt.therapistId == uid;
                final isPatient = appt.patientId == uid;
                if (!isTherapist && !isPatient) {
                  return const _NotFound();
                }
                return _DetailBody(
                  appointment: appt,
                  isTherapist: isTherapist,
                  repo: _repo,
                );
              },
            ),
    );
  }

  void _safePop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      // Fallback when the screen is opened directly via deep link with no
      // history stack — go to the patient appointment list.
      context.go('/main/my-appointments');
    }
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.appointment,
    required this.isTherapist,
    required this.repo,
  });

  final Appointment appointment;
  final bool isTherapist;
  final AppointmentRepository repo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fullDate = DateFormat("EEEE d 'de' MMMM y", 'es_ES')
        .format(appointment.dateTime);
    final start = DateFormat('HH:mm').format(appointment.dateTime);
    final end = DateFormat('HH:mm').format(appointment.endTime);
    final lookupId =
        isTherapist ? appointment.patientId : appointment.therapistId;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header card with date/time + status + type
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                appointment.status.color.withValues(alpha: 0.15),
                appointment.status.color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: appointment.status.color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${fullDate[0].toUpperCase()}${fullDate.substring(1)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$start – $end',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: appointment.status.color,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  AppointmentStatusChip(status: appointment.status),
                  AppointmentTypeChip(type: appointment.type),
                ],
              ),
            ],
          ),
        ),

        if (appointment.status == AppointmentStatus.pending) ...[
          const SizedBox(height: 16),
          _PendingBanner(isTherapist: isTherapist),
        ],

        const SizedBox(height: 20),

        // Other party identity card
        _OtherPartyCard(
          userId: lookupId,
          isTherapist: isTherapist,
        ),

        if ((appointment.sessionType ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Tipo de sesión',
            child: Text(
              appointment.sessionType!,
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
            ),
          ),
        ],

        if ((appointment.patientNotes ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Motivo del paciente',
            child: Text(
              appointment.patientNotes!,
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
            ),
          ),
        ],

        if ((appointment.notes ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Notas del terapeuta',
            child: Text(
              appointment.notes!,
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
            ),
          ),
        ],

        const SizedBox(height: 24),

        if (isTherapist)
          _TherapistActions(appointment: appointment, repo: repo)
        else
          _PatientActions(appointment: appointment, repo: repo),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.calendarOff, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No encontramos esta cita',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Es posible que haya sido cancelada o no tengas acceso.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.isTherapist});
  final bool isTherapist;

  @override
  Widget build(BuildContext context) {
    final amber = AppointmentStatus.pending.color;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.clock, color: amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isTherapist
                  ? 'Esta cita está pendiente de tu confirmación.'
                  : 'Pendiente de confirmación por tu terapeuta.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: amber.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherPartyCard extends StatelessWidget {
  const _OtherPartyCard({
    required this.userId,
    required this.isTherapist,
  });

  final String userId;
  final bool isTherapist;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? const <String, dynamic>{};
        final name = '${data['name'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        final specialty = data['specialty'] as String?;
        final photoUrl = data['photoUrl'] as String?;
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Icon(
                        isTherapist ? LucideIcons.user : LucideIcons.stethoscope,
                        color: colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTherapist ? 'Paciente' : 'Terapeuta',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name.isEmpty ? 'Cargando…' : name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (!isTherapist && (specialty ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        specialty!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

// ── Patient actions ──────────────────────────────────────────────────

class _PatientActions extends StatelessWidget {
  const _PatientActions({
    required this.appointment,
    required this.repo,
  });

  final Appointment appointment;
  final AppointmentRepository repo;

  @override
  Widget build(BuildContext context) {
    return switch (appointment.status) {
      AppointmentStatus.pending => _SingleButton(
          label: 'Cancelar solicitud',
          color: const Color(0xFFE53935),
          icon: LucideIcons.x,
          outlined: true,
          onPressed: () => _confirmCancel(context),
        ),
      AppointmentStatus.confirmed => Column(
          children: [
            _SingleButton(
              label: 'Agregar al calendario',
              color: Theme.of(context).colorScheme.primary,
              icon: LucideIcons.calendarPlus,
              outlined: false,
              onPressed: () => _addToCalendar(context),
            ),
            const SizedBox(height: 12),
            _SingleButton(
              label: 'Cancelar cita',
              color: const Color(0xFFE53935),
              icon: LucideIcons.x,
              outlined: true,
              onPressed: () => _confirmCancel(context),
            ),
          ],
        ),
      AppointmentStatus.cancelled => const _StatusBanner(
          message: 'Cita cancelada',
          color: Color(0xFFE53935),
        ),
      AppointmentStatus.completed => const _SingleButton(
          label: 'Calificar sesión (Próximamente)',
          color: Color(0xFF1E88E5),
          icon: LucideIcons.star,
          outlined: true,
          onPressed: null,
        ),
    };
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar esta cita?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, mantener'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await repo.cancelAppointment(appointment.id, cancellerId: uid);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita cancelada.')),
      );
    } on AppointmentException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _addToCalendar(BuildContext context) async {
    final event = cal.Event(
      title: 'Cita con tu terapeuta',
      description: appointment.patientNotes ?? '',
      startDate: appointment.dateTime,
      endDate: appointment.endTime,
    );
    final ok = await cal.Add2Calendar.addEvent2Cal(event);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Evento agregado al calendario.'
              : 'No se pudo abrir el calendario.',
        ),
      ),
    );
  }
}

// ── Therapist actions ────────────────────────────────────────────────

class _TherapistActions extends StatefulWidget {
  const _TherapistActions({
    required this.appointment,
    required this.repo,
  });

  final Appointment appointment;
  final AppointmentRepository repo;

  @override
  State<_TherapistActions> createState() => _TherapistActionsState();
}

class _TherapistActionsState extends State<_TherapistActions> {
  late TextEditingController _notesController;
  bool _savingNotes = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _notesController =
        TextEditingController(text: widget.appointment.notes ?? '');
  }

  @override
  void didUpdateWidget(covariant _TherapistActions old) {
    super.didUpdateWidget(old);
    final incoming = widget.appointment.notes ?? '';
    if (old.appointment.id != widget.appointment.id ||
        (old.appointment.notes ?? '') != incoming) {
      _notesController.text = incoming;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.appointment.status) {
      AppointmentStatus.pending => Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SingleButton(
                    label: 'Confirmar',
                    color: const Color(0xFF43A047),
                    icon: LucideIcons.check,
                    outlined: false,
                    onPressed: _busy ? null : _confirm,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SingleButton(
                    label: 'Rechazar',
                    color: const Color(0xFFE53935),
                    icon: LucideIcons.x,
                    outlined: true,
                    onPressed: _busy ? null : _cancel,
                  ),
                ),
              ],
            ),
          ],
        ),
      AppointmentStatus.confirmed => Column(
          children: [
            _SingleButton(
              label: 'Marcar como completada',
              color: const Color(0xFF1E88E5),
              icon: LucideIcons.check,
              outlined: false,
              onPressed: _busy ? null : _complete,
            ),
            const SizedBox(height: 12),
            _SingleButton(
              label: 'Reprogramar',
              color: const Color(0xFF6B7280),
              icon: LucideIcons.calendarClock,
              outlined: true,
              onPressed: _busy ? null : _reschedule,
            ),
            const SizedBox(height: 12),
            _SingleButton(
              label: 'Cancelar cita',
              color: const Color(0xFFE53935),
              icon: LucideIcons.x,
              outlined: true,
              onPressed: _busy ? null : _cancel,
            ),
          ],
        ),
      AppointmentStatus.completed => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notas de la sesión',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Agrega notas sobre la sesión…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SingleButton(
              label: 'Guardar notas',
              color: Theme.of(context).colorScheme.primary,
              icon: LucideIcons.save,
              outlined: false,
              onPressed: _savingNotes ? null : _saveNotes,
            ),
          ],
        ),
      AppointmentStatus.cancelled => const _StatusBanner(
          message: 'Cita cancelada',
          color: Color(0xFFE53935),
        ),
    };
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await widget.repo.confirmAppointment(widget.appointment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita confirmada.')),
      );
    } on AppointmentException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete() async {
    final result = await showDialog<_CompleteDialogResult>(
      context: context,
      builder: (ctx) => const _CompleteDialog(),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repo.completeAppointment(
        widget.appointment.id,
        notes: result.notes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita marcada como completada.')),
      );
    } on AppointmentException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar esta cita?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'El paciente recibirá una notificación. Esta acción no se puede deshacer.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, mantener'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      await widget.repo.cancelAppointment(
        widget.appointment.id,
        cancellerId: uid,
        reason: reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita cancelada.')),
      );
    } on AppointmentException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reschedule() async {
    await RescheduleAppointmentSheet.show(
      context,
      appointment: widget.appointment,
    );
  }

  Future<void> _saveNotes() async {
    setState(() => _savingNotes = true);
    try {
      await widget.repo.updateAppointment(widget.appointment.id, {
        'notes': _notesController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notas guardadas.')),
      );
    } on AppointmentException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _savingNotes = false);
    }
  }
}

class _CompleteDialogResult {
  const _CompleteDialogResult({this.notes});
  final String? notes;
}

class _CompleteDialog extends StatefulWidget {
  const _CompleteDialog();

  @override
  State<_CompleteDialog> createState() => _CompleteDialogState();
}

class _CompleteDialogState extends State<_CompleteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Marcar esta cita como completada?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notas de la sesión (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            _CompleteDialogResult(
              notes: _controller.text.trim().isEmpty
                  ? null
                  : _controller.text.trim(),
            ),
          ),
          child: const Text('Marcar completada'),
        ),
      ],
    );
  }
}

// ── Bits ─────────────────────────────────────────────────────────────

class _SingleButton extends StatelessWidget {
  const _SingleButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.outlined,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool outlined;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(vertical: 14),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: style.copyWith(
                foregroundColor: WidgetStateProperty.all(color),
                side: WidgetStateProperty.all(BorderSide(color: color)),
              ),
              child: child,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: style.copyWith(
                backgroundColor: WidgetStateProperty.all(color),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              child: child,
            ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.color});
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
