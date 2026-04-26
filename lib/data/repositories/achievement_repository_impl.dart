import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_achievement_entity.dart';
import '../../domain/repositories/achievement_repository.dart';

class AchievementRepositoryImpl implements AchievementRepository {
  AchievementRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('user_achievements');

  /// Deterministic doc ID so unlocks are idempotent — re-running
  /// `evaluate` for the same user and achievement is a safe overwrite.
  String _docId(String userId, String achievementId) =>
      '${userId}_$achievementId';

  @override
  Future<Set<String>> getUnlockedIds(String userId) async {
    final query = await _col.where('userId', isEqualTo: userId).get();
    return query.docs
        .map((d) => d.data()['achievementId'] as String?)
        .whereType<String>()
        .toSet();
  }

  @override
  Stream<List<UserAchievementEntity>> watchUnlocked(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => _fromMap(d.data()))
            .whereType<UserAchievementEntity>()
            .toList());
  }

  @override
  Future<void> unlock({
    required String userId,
    required String achievementId,
  }) {
    return _col.doc(_docId(userId, achievementId)).set({
      'userId': userId,
      'achievementId': achievementId,
      'unlockedAt': FieldValue.serverTimestamp(),
    });
  }

  UserAchievementEntity? _fromMap(Map<String, dynamic> data) {
    final userId = data['userId'] as String?;
    final achievementId = data['achievementId'] as String?;
    final ts = data['unlockedAt'];
    if (userId == null || achievementId == null) return null;
    return UserAchievementEntity(
      userId: userId,
      achievementId: achievementId,
      unlockedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
