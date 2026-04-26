import '../core/utils/logger.dart';
import '../data/repositories/achievement_repository_impl.dart';
import '../domain/constants/achievement_catalog.dart';
import '../domain/entities/achievement_entity.dart';
import '../domain/repositories/achievement_repository.dart';

/// Snapshot of all signals the achievement engine needs to decide which
/// badges should unlock. Callers only have to fill in the values they
/// actually have — counters they don't track yet can stay at 0 and the
/// related achievements will simply not unlock.
class AchievementEvaluationContext {
  const AchievementEvaluationContext({
    required this.userId,
    this.totalSessions = 0,
    this.currentStreak = 0,
    this.consecutivePainLogDays = 0,
    this.noraMessageCount = 0,
  });

  final String userId;
  final int totalSessions;
  final int currentStreak;
  final int consecutivePainLogDays;
  final int noraMessageCount;
}

/// Evaluates the achievement catalog against a user state snapshot and
/// persists any newly unlocked achievements.
///
/// The catalog itself is a code constant; the unlock predicates live here
/// so the domain layer stays dependency-free.
class AchievementService {
  AchievementService._internal();
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;

  AchievementRepository _repository = AchievementRepositoryImpl();

  void debugOverride({AchievementRepository? repository}) {
    if (repository != null) _repository = repository;
  }

  Stream<Set<String>> watchUnlockedIds(String userId) =>
      _repository.watchUnlocked(userId).map(
            (list) => list.map((u) => u.achievementId).toSet(),
          );

  /// Returns the catalog entries that *just* unlocked. Already-unlocked
  /// achievements are skipped silently.
  Future<List<AchievementEntity>> evaluate(
    AchievementEvaluationContext ctx,
  ) async {
    final alreadyUnlocked = await _repository.getUnlockedIds(ctx.userId);
    final newlyUnlocked = <AchievementEntity>[];

    for (final achievement in achievementCatalog) {
      if (alreadyUnlocked.contains(achievement.id)) continue;
      if (!_meetsCondition(achievement.id, ctx)) continue;

      await _repository.unlock(
        userId: ctx.userId,
        achievementId: achievement.id,
      );
      newlyUnlocked.add(achievement);
    }

    if (newlyUnlocked.isNotEmpty) {
      AppLogger.info(
        'Logros desbloqueados: ${newlyUnlocked.map((a) => a.id).toList()}',
        tag: 'Achievement',
      );
    }

    return newlyUnlocked;
  }

  bool _meetsCondition(String id, AchievementEvaluationContext ctx) {
    switch (id) {
      case 'first_step':
        return ctx.totalSessions >= 1;
      case 'pain_fighter':
        return ctx.consecutivePainLogDays >= 3;
      case 'chatterbox':
        return ctx.noraMessageCount >= 10;
      case 'week_warrior':
        return ctx.currentStreak >= 7;
      case 'dedicated':
        return ctx.totalSessions >= 30;
      case 'month_master':
        return ctx.currentStreak >= 30;
      default:
        return false;
    }
  }
}
