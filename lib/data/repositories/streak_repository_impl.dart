import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/streak_entity.dart';
import '../../domain/repositories/streak_repository.dart';

/// Firestore-backed implementation. Stores one document per user at
/// `user_streaks/{userId}` to keep reads cheap and rule logic simple.
class StreakRepositoryImpl implements StreakRepository {
  StreakRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('user_streaks');

  @override
  Stream<StreakEntity?> watchStreak(String userId) {
    return _col.doc(userId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return _fromMap(userId, snap.data()!);
    });
  }

  @override
  Future<StreakEntity?> getStreak(String userId) async {
    final snap = await _col.doc(userId).get();
    if (!snap.exists) return null;
    return _fromMap(userId, snap.data()!);
  }

  @override
  Future<void> saveStreak(StreakEntity streak) {
    return _col.doc(streak.userId).set(_toMap(streak));
  }

  Map<String, dynamic> _toMap(StreakEntity s) => {
        'userId': s.userId,
        'currentStreak': s.currentStreak,
        'longestStreak': s.longestStreak,
        'lastActivityDate': s.lastActivityDate == null
            ? null
            : Timestamp.fromDate(s.lastActivityDate!),
        'milestones': s.milestonesReached,
      };

  StreakEntity _fromMap(String userId, Map<String, dynamic> data) {
    final ts = data['lastActivityDate'];
    return StreakEntity(
      userId: userId,
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (data['longestStreak'] as num?)?.toInt() ?? 0,
      lastActivityDate: ts is Timestamp ? ts.toDate() : null,
      milestonesReached: (data['milestones'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
    );
  }
}
