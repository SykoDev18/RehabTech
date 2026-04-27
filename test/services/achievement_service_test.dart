import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/domain/entities/user_achievement_entity.dart';
import 'package:rehabtech/domain/repositories/achievement_repository.dart';
import 'package:rehabtech/services/achievement_service.dart';

class _FakeAchievementRepo implements AchievementRepository {
  final Map<String, Set<String>> _unlocked = {};

  @override
  Future<Set<String>> getUnlockedIds(String userId) async {
    return Set<String>.from(_unlocked[userId] ?? <String>{});
  }

  @override
  Stream<List<UserAchievementEntity>> watchUnlocked(String userId) async* {
    final ids = _unlocked[userId] ?? <String>{};
    yield ids
        .map((id) => UserAchievementEntity(
              userId: userId,
              achievementId: id,
              unlockedAt: DateTime(2026, 1, 1),
            ))
        .toList();
  }

  @override
  Future<void> unlock({required String userId, required String achievementId}) async {
    (_unlocked[userId] ??= <String>{}).add(achievementId);
  }
}

void main() {
  const userId = 'u1';
  late _FakeAchievementRepo repo;

  setUp(() {
    repo = _FakeAchievementRepo();
    AchievementService().debugOverride(repository: repo);
  });

  group('AchievementService.evaluate', () {
    test('primera sesión desbloquea "first_step"', () async {
      final unlocked = await AchievementService().evaluate(
        const AchievementEvaluationContext(
          userId: userId,
          totalSessions: 1,
        ),
      );
      expect(unlocked.map((a) => a.id), contains('first_step'));
    });

    test('segunda evaluación con mismo contexto no re-desbloquea', () async {
      final ctx = const AchievementEvaluationContext(
        userId: userId,
        totalSessions: 1,
      );
      await AchievementService().evaluate(ctx);
      final secondPass = await AchievementService().evaluate(ctx);
      expect(secondPass, isEmpty);
    });

    test('streak de 7 días desbloquea "week_warrior"', () async {
      final unlocked = await AchievementService().evaluate(
        const AchievementEvaluationContext(
          userId: userId,
          currentStreak: 7,
        ),
      );
      expect(unlocked.map((a) => a.id), contains('week_warrior'));
    });

    test('streak de 30 días desbloquea week_warrior Y month_master', () async {
      final unlocked = await AchievementService().evaluate(
        const AchievementEvaluationContext(
          userId: userId,
          currentStreak: 30,
        ),
      );
      final ids = unlocked.map((a) => a.id).toSet();
      expect(ids, containsAll(['week_warrior', 'month_master']));
    });

    test('30 sesiones desbloquea "dedicated" (y "first_step")', () async {
      final unlocked = await AchievementService().evaluate(
        const AchievementEvaluationContext(
          userId: userId,
          totalSessions: 30,
        ),
      );
      final ids = unlocked.map((a) => a.id).toSet();
      expect(ids, containsAll(['first_step', 'dedicated']));
    });

    test('3 días consecutivos de dolor desbloquea "pain_fighter"', () async {
      final unlocked = await AchievementService().evaluate(
        const AchievementEvaluationContext(
          userId: userId,
          consecutivePainLogDays: 3,
        ),
      );
      expect(unlocked.map((a) => a.id), contains('pain_fighter'));
    });

    test('10 mensajes a Nora desbloquea "chatterbox"', () async {
      final unlocked = await AchievementService().evaluate(
        const AchievementEvaluationContext(
          userId: userId,
          noraMessageCount: 10,
        ),
      );
      expect(unlocked.map((a) => a.id), contains('chatterbox'));
    });

    test('contadores por debajo del umbral no desbloquean', () async {
      final unlocked = await AchievementService().evaluate(
        const AchievementEvaluationContext(
          userId: userId,
          totalSessions: 0,
          currentStreak: 6,
          consecutivePainLogDays: 2,
          noraMessageCount: 9,
        ),
      );
      expect(unlocked, isEmpty);
    });

    test('un desbloqueo nuevo no afecta los previos', () async {
      // Primera evaluación: solo first_step
      await AchievementService().evaluate(
        const AchievementEvaluationContext(
          userId: userId,
          totalSessions: 1,
        ),
      );

      // Segunda evaluación con streak alto: solo week_warrior + month_master
      final second = await AchievementService().evaluate(
        const AchievementEvaluationContext(
          userId: userId,
          totalSessions: 1, // ya estaba unlocked
          currentStreak: 30,
        ),
      );
      final ids = second.map((a) => a.id).toSet();
      expect(ids, isNot(contains('first_step')));
      expect(ids, containsAll(['week_warrior', 'month_master']));
    });
  });
}
