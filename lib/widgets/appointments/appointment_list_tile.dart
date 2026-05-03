import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/models/appointment.dart';
import 'appointment_status_chip.dart';
import 'appointment_type_chip.dart';

/// Compact row used in patient and therapist appointment lists.
///
/// [otherPartyName] is rendered as the title — for the patient list this is
/// the therapist's display name; for the therapist list it's the patient's
/// name. Resolution is the caller's responsibility so the tile can stay
/// stateless and avoid per-row Firestore reads.
class AppointmentListTile extends StatelessWidget {
  const AppointmentListTile({
    super.key,
    required this.appointment,
    required this.otherPartyName,
    required this.onTap,
  });

  final Appointment appointment;
  final String otherPartyName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFmt =
        DateFormat("EEEE d 'de' MMM", 'es_ES').format(appointment.dateTime);
    final timeFmt = DateFormat('HH:mm').format(appointment.dateTime);
    final accent = appointment.status.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.calendar, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherPartyName.isEmpty ? 'Cita' : otherPartyName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dateFmt[0].toUpperCase()}${dateFmt.substring(1)} · $timeFmt',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
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
            Icon(
              LucideIcons.chevronRight,
              color: colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
