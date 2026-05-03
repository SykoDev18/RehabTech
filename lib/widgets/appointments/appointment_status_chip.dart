import 'package:flutter/material.dart';

import '../../domain/models/appointment.dart';

/// Small pill that visualizes the four [AppointmentStatus] states using the
/// status's own color. Tinted background + bold colored label.
class AppointmentStatusChip extends StatelessWidget {
  const AppointmentStatusChip({required this.status, super.key});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
