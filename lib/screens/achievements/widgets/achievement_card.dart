import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../domain/entities/achievement_entity.dart';

/// Visual tile for a single achievement.
///
/// Locked achievements render desaturated with a lock badge; unlocked ones
/// show the original icon, accent color, and (optionally) the unlock date.
class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.achievement,
    required this.unlocked,
    this.unlockedAt,
  });

  final AchievementEntity achievement;
  final bool unlocked;
  final DateTime? unlockedAt;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFFF59E0B);
    final iconColor = unlocked ? accent : Colors.grey.shade400;
    final titleColor = unlocked ? const Color(0xFF111827) : Colors.grey.shade500;
    final bgColor = unlocked
        ? accent.withValues(alpha: 0.08)
        : Colors.grey.shade100;
    final borderColor = unlocked
        ? accent.withValues(alpha: 0.3)
        : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: unlocked ? Colors.white : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _resolveIcon(achievement.iconName),
                  size: 28,
                  color: iconColor,
                ),
              ),
              if (!unlocked)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.lock, size: 12, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            unlocked && unlockedAt != null
                ? DateFormat('d MMM yyyy', 'es_ES').format(unlockedAt!)
                : achievement.condition,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '+${achievement.points} pts',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: unlocked ? accent : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _resolveIcon(String name) {
    switch (name) {
      case 'footprints':
        return LucideIcons.footprints;
      case 'shield':
        return LucideIcons.shield;
      case 'messages_square':
        return LucideIcons.messagesSquare;
      case 'flame':
        return LucideIcons.flame;
      case 'medal':
        return LucideIcons.medal;
      case 'trophy':
        return LucideIcons.trophy;
      default:
        return LucideIcons.award;
    }
  }
}
