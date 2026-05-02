import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehabtech/domain/entities/therapist_license_entity.dart';

/// Compact visual indicator for a therapist's license verification state.
///
/// Renders nothing for [LicenseStatus.unverified] so it can be safely dropped
/// next to a therapist name without leaking "unverified" labels everywhere.
class LicenseStatusBadge extends StatelessWidget {
  final LicenseStatus status;

  /// When true, renders only the icon. Useful for dense rows.
  final bool compact;

  /// Optional tap callback. When provided and the status is [verified],
  /// callers typically open a sheet with the SEP details.
  final VoidCallback? onTap;

  const LicenseStatusBadge({
    required this.status,
    this.compact = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      LicenseStatus.verified => _badge(
          context,
          icon: LucideIcons.badgeCheck,
          label: 'Cédula verificada SEP',
          color: const Color(0xFF22C55E),
        ),
      LicenseStatus.pending ||
      LicenseStatus.manualReview =>
        _badge(
          context,
          icon: LucideIcons.clock,
          label: 'Verificación pendiente',
          color: const Color(0xFFF59E0B),
        ),
      LicenseStatus.rejected => _badge(
          context,
          icon: LucideIcons.circleAlert,
          label: 'No verificado',
          color: const Color(0xFFEF4444),
        ),
      LicenseStatus.unverified => const SizedBox.shrink(),
    };
  }

  Widget _badge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: color),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: content,
      ),
    );
  }
}
