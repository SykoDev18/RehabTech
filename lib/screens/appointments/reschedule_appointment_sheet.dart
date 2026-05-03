import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/repositories/firestore_appointment_repository.dart';
import '../../domain/exceptions/appointment_exception.dart';
import '../../domain/models/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';

/// Therapist-side modal that reschedules an existing appointment.
///
/// Same date/time pickers as [BookAppointmentSheet] step 1+2 but
/// pre-selected to the appointment's current values. Confirming writes
/// `dateTime` and resets `status` to `pending` — the patient must
/// re-confirm. The Cloud Function trigger (TODO) handles notifying them.
class RescheduleAppointmentSheet extends StatefulWidget {
  const RescheduleAppointmentSheet({
    super.key,
    required this.appointment,
    this.repository,
  });

  final Appointment appointment;
  final AppointmentRepository? repository;

  static Future<bool?> show(
    BuildContext context, {
    required Appointment appointment,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RescheduleAppointmentSheet(appointment: appointment),
    );
  }

  @override
  State<RescheduleAppointmentSheet> createState() =>
      _RescheduleAppointmentSheetState();
}

class _RescheduleAppointmentSheetState
    extends State<RescheduleAppointmentSheet> {
  late final AppointmentRepository _repo;
  late DateTime _date;
  late TimeOfDay _time;
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
    _date = widget.appointment.dateTime;
    _time = TimeOfDay.fromDateTime(widget.appointment.dateTime);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final dt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    try {
      await _repo.updateAppointment(widget.appointment.id, {
        'dateTime': Timestamp.fromDate(dt),
        'status': AppointmentStatus.pending.toFirestore(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cita reprogramada. El paciente debe confirmar nuevamente.',
          ),
        ),
      );
    } on AppointmentException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final firstDate = _date.isBefore(tomorrow) ? _date : tomorrow;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Reprogramar cita',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE69C)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.info,
                          size: 16, color: Color(0xFF856404)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'La cita volverá a estado "Pendiente" hasta que el paciente la confirme.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF856404),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fecha',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CalendarDatePicker(
                        initialDate: _date,
                        firstDate: firstDate,
                        lastDate: DateTime.now()
                            .add(const Duration(days: 90)),
                        onDateChanged: (d) => setState(() => _date = d),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        DateFormat("EEEE d 'de' MMMM", 'es_ES')
                            .format(_date),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Hora',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final t in _slots)
                            FilterChip(
                              label: Text(t.format(context)),
                              selected: _time.hour == t.hour,
                              onSelected: (_) => setState(() => _time = t),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border:
                      Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Reprogramar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
