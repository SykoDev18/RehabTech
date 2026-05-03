import 'package:flutter/material.dart';

import '../../domain/models/appointment.dart';

/// Compact icon + label pill for the appointment modality (presencial /
/// virtual). Returns a [SizedBox.shrink] when [type] is null so callers can
/// drop it in unconditionally without sprinkling null-checks.
class AppointmentTypeChip extends StatelessWidget {
  const AppointmentTypeChip({required this.type, super.key});

  final AppointmentType? type;

  @override
  Widget build(BuildContext context) {
    final t = type;
    if (t == null) return const SizedBox.shrink();
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(t.icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            t.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
