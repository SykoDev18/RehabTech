import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/repositories/firestore_appointment_repository.dart';
import '../../domain/exceptions/appointment_exception.dart';
import '../../domain/models/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';

/// Three-step modal sheet for patient self-booking.
///
/// Step 1 — pick a date (tomorrow → today+60d).
/// Step 2 — pick an hour from a fixed slot list (08–18, 60-min slots).
///          Slots already taken by this therapist on that day are disabled.
/// Step 3 — choose modality, optionally write a reason, confirm.
///
/// On confirm, writes a new `appointments` doc with status='pending' and
/// returns the generated id via the modal `Navigator.pop` value (used by
/// the caller to e.g. navigate to the detail screen).
class BookAppointmentSheet extends StatefulWidget {
  const BookAppointmentSheet({
    super.key,
    required this.patientId,
    required this.therapistId,
    this.repository,
  });

  final String patientId;
  final String therapistId;

  /// Override for tests. In production [FirestoreAppointmentRepository] is
  /// constructed lazily so the modal stays decoupled from DI wiring.
  final AppointmentRepository? repository;

  /// Convenience to open the sheet. Returns the new appointment id on
  /// success, or `null` if the user closed it.
  static Future<String?> show(
    BuildContext context, {
    required String patientId,
    required String therapistId,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookAppointmentSheet(
        patientId: patientId,
        therapistId: therapistId,
      ),
    );
  }

  @override
  State<BookAppointmentSheet> createState() => _BookAppointmentSheetState();
}

class _BookAppointmentSheetState extends State<BookAppointmentSheet> {
  late final AppointmentRepository _repo;
  final _notesController = TextEditingController();

  int _step = 0;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  AppointmentType _modality = AppointmentType.presencial;
  bool _submitting = false;

  static const List<TimeOfDay> _slots = [
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 16, minute: 0),
    TimeOfDay(hour: 17, minute: 0),
    TimeOfDay(hour: 18, minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? FirestoreAppointmentRepository();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    return switch (_step) {
      0 => _selectedDate != null,
      1 => _selectedTime != null,
      2 => true,
      _ => false,
    };
  }

  Future<void> _confirm() async {
    final date = _selectedDate;
    final time = _selectedTime;
    if (date == null || time == null) return;

    setState(() => _submitting = true);
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final now = DateTime.now();
    final appt = Appointment(
      id: '',
      therapistId: widget.therapistId,
      patientId: widget.patientId,
      dateTime: dt,
      durationMinutes: 60,
      status: AppointmentStatus.pending,
      type: _modality,
      patientNotes:
          _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: now,
      updatedAt: now,
    );

    try {
      final id = await _repo.createAppointment(appt);
      if (!mounted) return;
      Navigator.of(context).pop(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Cita solicitada! Tu terapeuta la confirmará pronto.',
          ),
          backgroundColor: Color(0xFF43A047),
        ),
      );
    } on AppointmentException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo agendar la cita. Inténtalo de nuevo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              _DragHandle(),
              _StepHeader(step: _step),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: switch (_step) {
                    0 => _StepDate(
                        selected: _selectedDate,
                        onSelected: (d) =>
                            setState(() => _selectedDate = d),
                      ),
                    1 => _StepTime(
                        therapistId: widget.therapistId,
                        date: _selectedDate!,
                        slots: _slots,
                        selected: _selectedTime,
                        onSelected: (t) =>
                            setState(() => _selectedTime = t),
                      ),
                    _ => _StepConfirm(
                        date: _selectedDate!,
                        time: _selectedTime!,
                        modality: _modality,
                        notesController: _notesController,
                        onModalityChanged: (m) =>
                            setState(() => _modality = m),
                      ),
                  },
                ),
              ),
              _Footer(
                step: _step,
                canAdvance: _canAdvance,
                submitting: _submitting,
                onBack: _step == 0
                    ? null
                    : () => setState(() => _step -= 1),
                onNext: _step < 2
                    ? () => setState(() => _step += 1)
                    : _confirm,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});
  final int step;

  static const _titles = [
    '¿Qué día prefieres?',
    '¿A qué hora?',
    'Confirma tu cita',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= step
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 4),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _titles[step],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Paso ${step + 1} de 3',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDate extends StatelessWidget {
  const _StepDate({required this.selected, required this.onSelected});
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));
    final maxDate = tomorrow.add(const Duration(days: 60));

    return CalendarDatePicker(
      initialDate: selected ?? tomorrow,
      firstDate: tomorrow,
      lastDate: maxDate,
      onDateChanged: onSelected,
    );
  }
}

class _StepTime extends StatelessWidget {
  const _StepTime({
    required this.therapistId,
    required this.date,
    required this.slots,
    required this.selected,
    required this.onSelected,
  });

  final String therapistId;
  final DateTime date;
  final List<TimeOfDay> slots;
  final TimeOfDay? selected;
  final ValueChanged<TimeOfDay> onSelected;

  @override
  Widget build(BuildContext context) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('therapistId', isEqualTo: therapistId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dateTime', isLessThan: Timestamp.fromDate(end))
          .snapshots(),
      builder: (context, snap) {
        final taken = <int>{}; // hour-of-day occupied (cancelled excluded)
        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final data = doc.data();
            final ts = data['dateTime'];
            final status = data['status'] as String?;
            if (ts is Timestamp && status != 'cancelled') {
              final dt = ts.toDate();
              taken.add(dt.hour);
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat("EEEE d 'de' MMMM", 'es_ES').format(date),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            if (snap.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final t in slots)
                    FilterChip(
                      label: Text(t.format(context)),
                      selected: selected?.hour == t.hour,
                      onSelected: taken.contains(t.hour)
                          ? null
                          : (_) => onSelected(t),
                      backgroundColor: taken.contains(t.hour)
                          ? Colors.grey[100]
                          : null,
                      labelStyle: TextStyle(
                        color: taken.contains(t.hour)
                            ? Colors.grey[400]
                            : null,
                        decoration: taken.contains(t.hour)
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.info,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'Horarios ocupados aparecen tachados',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StepConfirm extends StatelessWidget {
  const _StepConfirm({
    required this.date,
    required this.time,
    required this.modality,
    required this.notesController,
    required this.onModalityChanged,
  });

  final DateTime date;
  final TimeOfDay time;
  final AppointmentType modality;
  final TextEditingController notesController;
  final ValueChanged<AppointmentType> onModalityChanged;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat("EEEE d 'de' MMMM", 'es_ES').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(
                icon: LucideIcons.calendar,
                label: '${formatted[0].toUpperCase()}${formatted.substring(1)}',
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                icon: LucideIcons.clock,
                label: time.format(context),
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                icon: modality.icon,
                label: modality.displayName,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Modalidad',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<AppointmentType>(
          segments: [
            for (final t in AppointmentType.values)
              ButtonSegment(
                value: t,
                label: Text(t.displayName),
                icon: Icon(t.icon),
              ),
          ],
          selected: {modality},
          onSelectionChanged: (s) => onModalityChanged(s.first),
        ),
        const SizedBox(height: 20),
        const Text(
          'Motivo de la consulta (opcional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: notesController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Describe brevemente lo que necesitas...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.step,
    required this.canAdvance,
    required this.submitting,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final bool canAdvance;
  final bool submitting;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (onBack != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: submitting ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Atrás'),
                ),
              ),
            if (onBack != null) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (canAdvance && !submitting) ? onNext : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(step < 2 ? 'Siguiente' : 'Confirmar Cita'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
