import '../entities/streak_entity.dart';

abstract class StreakRepository {
  /// Live stream of the user's streak. Emits null until a streak document exists.
  Stream<StreakEntity?> watchStreak(String userId);

  /// One-shot read.
  Future<StreakEntity?> getStreak(String userId);

  /// Upsert. Implementations must persist the entity in full.
  Future<void> saveStreak(StreakEntity streak);
}
