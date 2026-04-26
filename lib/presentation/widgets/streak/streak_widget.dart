import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../domain/entities/streak_entity.dart';
import '../../../services/streak_service.dart';

/// Compact "current streak" indicator. Subscribes directly to the streak
/// stream for the signed-in user and animates when the count changes.
///
/// `onTap` is optional — pass a callback if you want to navigate to a streak
/// history screen. When null, the widget is non-interactive.
class StreakWidget extends StatelessWidget {
  const StreakWidget({super.key, this.onTap, this.compact = false});

  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<StreakEntity?>(
      stream: StreakService().watch(user.uid),
      builder: (context, snapshot) {
        final streak = snapshot.data?.currentStreak ?? 0;
        return _StreakCard(streak: streak, onTap: onTap, compact: compact);
      },
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.streak,
    required this.onTap,
    required this.compact,
  });

  final int streak;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isActive = streak > 0;
    final flameColor =
        isActive ? const Color(0xFFF97316) : Colors.grey.shade400;

    final card = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFFFFEDD5), Color(0xFFFEE2E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFFF97316).withValues(alpha: 0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.flame, color: flameColor, size: compact ? 20 : 24),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Text(
              '$streak',
              key: ValueKey(streak),
              style: TextStyle(
                fontSize: compact ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFFC2410C) : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            streak == 1 ? 'día' : 'días',
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFFC2410C) : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: card,
    );
  }
}
