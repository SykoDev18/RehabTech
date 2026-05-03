import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/models/appointment.dart';
import 'appointment_status_chip.dart';
import 'appointment_type_chip.dart';

/// Larger card variant for the therapist's "today" strip and the home
/// "upcoming next 3" widget. Time range is the focal point; the rest is
/// secondary context.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.patientName,
    required this.onTap,
    this.width = 240,
  });

  final Appointment appointment;
  final String patientName;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final start = DateFormat('HH:mm').format(appointment.dateTime);
    final end = DateFormat('HH:mm').format(appointment.endTime);
    final accent = appointment.status.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.clock, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  '$start – $end',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              patientName.isEmpty ? 'Paciente' : patientName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if ((appointment.sessionType ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                appointment.sessionType!,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                AppointmentStatusChip(status: appointment.status),
                AppointmentTypeChip(type: appointment.type),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
