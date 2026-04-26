import 'package:flutter/material.dart';

import '../../../domain/validators/password_validator.dart';

/// Compact visual feedback for password rules. Stateless — caller drives it
/// with the current password string and rebuilds on change.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showRequirements = true,
  });

  final String password;
  final bool showRequirements;

  @override
  Widget build(BuildContext context) {
    final result = PasswordValidator.validate(password);
    final strength = result.strength;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            final reached = index < result.satisfiedCount;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 3 ? 0 : 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 6,
                  decoration: BoxDecoration(
                    color: reached
                        ? _colorForStrength(strength, colorScheme)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          }),
        ),
        if (password.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            _labelForStrength(strength),
            style: textTheme.bodySmall?.copyWith(
              color: _colorForStrength(strength, colorScheme),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (showRequirements) ...[
          const SizedBox(height: 8),
          _RequirementRow(
            satisfied: result.hasMinLength,
            label: 'Al menos 8 caracteres',
          ),
          _RequirementRow(
            satisfied: result.hasUppercase,
            label: 'Una letra mayúscula',
          ),
          _RequirementRow(
            satisfied: result.hasNumber,
            label: 'Un número',
          ),
          _RequirementRow(
            satisfied: result.hasSpecialChar,
            label: 'Un carácter especial',
          ),
        ],
      ],
    );
  }

  Color _colorForStrength(PasswordStrength s, ColorScheme cs) {
    switch (s) {
      case PasswordStrength.weak:
        return const Color(0xFFEF4444);
      case PasswordStrength.medium:
        return const Color(0xFFF59E0B);
      case PasswordStrength.strong:
        return const Color(0xFF10B981);
      case PasswordStrength.veryStrong:
        return const Color(0xFF059669);
    }
  }

  String _labelForStrength(PasswordStrength s) {
    switch (s) {
      case PasswordStrength.weak:
        return 'Débil';
      case PasswordStrength.medium:
        return 'Media';
      case PasswordStrength.strong:
        return 'Fuerte';
      case PasswordStrength.veryStrong:
        return 'Muy fuerte';
    }
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.satisfied, required this.label});

  final bool satisfied;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = satisfied
        ? const Color(0xFF10B981)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
