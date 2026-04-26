import '../entities/user_achievement_entity.dart';

abstract class AchievementRepository {
  /// IDs of all achievements the user has unlocked. Useful for fast
  /// "already-unlocked?" checks during evaluation.
  Future<Set<String>> getUnlockedIds(String userId);

  /// Live stream of full unlock records for displaying the user's collection.
  Stream<List<UserAchievementEntity>> watchUnlocked(String userId);

  /// Persist an unlock. No-op if the record already exists (the rules
  /// disallow updates anyway).
  Future<void> unlock({required String userId, required String achievementId});
}
