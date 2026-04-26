/// Per-user record marking an achievement as unlocked. Persisted at
/// `user_achievements/{docId}` (one document per user+achievement).
class UserAchievementEntity {
  const UserAchievementEntity({
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
  });

  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
}
