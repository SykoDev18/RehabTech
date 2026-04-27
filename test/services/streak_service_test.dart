import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/domain/entities/streak_entity.dart';
import 'package:rehabtech/domain/repositories/streak_repository.dart';
import 'package:rehabtech/services/streak_service.dart';

/// In-memory implementation of [StreakRepository] for tests.
class _FakeStreakRepository implements StreakRepository {
  final Map<String, StreakEntity> _store = {};

  @override
  Future<StreakEntity?> getStreak(String userId) async => _store[userId];

  @override
  Future<void> saveStreak(StreakEntity streak) async {
    _store[streak.userId] = streak;
  }

  @override
  Stream<StreakEntity?> watchStreak(String userId) async* {
    yield _store[userId];
  }
}

void main() {
  const userId = 'u1';
  late _FakeStreakRepository repo;
  late DateTime clock;

  setUp(() {
    repo = _FakeStreakRepository();
    clock = DateTime(2026, 4, 26, 12, 0); // hora local arbitraria
    StreakService().debugOverride(repository: repo, now: () => clock);
  });

  group('updateStreak — primera actividad', () {
    test('sin documento previo crea streak=1, longest=1', () async {
      final result = await StreakService().updateStreak(userId);
      expect(result.changed, isTrue);
      expect(result.streak.currentStreak, 1);
      expect(result.streak.longestStreak, 1);
      expect(result.newMilestones, isEmpty);
    });

    test('persiste lastActivityDate normalizado a día sin hora', () async {
      await StreakService().updateStreak(userId);
      final saved = await repo.getStreak(userId);
      expect(saved, isNotNull);
      // El día es 2026-04-26 sin componente hora.
      expect(saved!.lastActivityDate, DateTime(2026, 4, 26));
    });
  });

  group('updateStreak — actividad el mismo día', () {
    test('una segunda llamada el mismo día es no-op', () async {
      await StreakService().updateStreak(userId);
      final second = await StreakService().updateStreak(userId);
      expect(second.changed, isFalse);
      expect(second.streak.currentStreak, 1);
      expect(second.newMilestones, isEmpty);
    });

    test('la hora del día no afecta — sigue siendo el mismo día', () async {
      await StreakService().updateStreak(userId);
      // Mover el reloj 8 horas adelante, mismo día calendario.
      clock = DateTime(2026, 4, 26, 20, 30);
      final result = await StreakService().updateStreak(userId);
      expect(result.changed, isFalse);
    });
  });

  group('updateStreak — actividad ayer', () {
    test('incrementa currentStreak', () async {
      await StreakService().updateStreak(userId);
      clock = DateTime(2026, 4, 27, 10, 0);
      final result = await StreakService().updateStreak(userId);
      expect(result.changed, isTrue);
      expect(result.streak.currentStreak, 2);
      expect(result.streak.longestStreak, 2);
    });
  });

  group('updateStreak — gap de 2+ días', () {
    test('resetea currentStreak a 1 pero conserva longestStreak', () async {
      // Construye una racha de 3 días.
      await StreakService().updateStreak(userId);
      clock = DateTime(2026, 4, 27);
      await StreakService().updateStreak(userId);
      clock = DateTime(2026, 4, 28);
      await StreakService().updateStreak(userId);

      final beforeGap = await repo.getStreak(userId);
      expect(beforeGap!.currentStreak, 3);
      expect(beforeGap.longestStreak, 3);

      // Salta 5 días → reset a 1, longest se mantiene en 3.
      clock = DateTime(2026, 5, 3);
      final result = await StreakService().updateStreak(userId);
      expect(result.streak.currentStreak, 1);
      expect(result.streak.longestStreak, 3);
    });
  });

  group('updateStreak — milestones', () {
    Future<void> bumpDays(int n) async {
      for (var i = 0; i < n; i++) {
        await StreakService().updateStreak(userId);
        clock = clock.add(const Duration(days: 1));
      }
    }

    test('al llegar a 3 días se reporta milestone 3', () async {
      await bumpDays(2); // streak = 2 al final del día 2
      final third = await StreakService().updateStreak(userId);
      expect(third.streak.currentStreak, 3);
      expect(third.newMilestones, equals([3]));
    });

    test('milestones ya reportados no se vuelven a disparar', () async {
      await bumpDays(3); // streak = 3, milestone 3 ya disparado en el último

      // Continuar al día 4 — sin nuevo milestone.
      final fourth = await StreakService().updateStreak(userId);
      expect(fourth.streak.currentStreak, 4);
      expect(fourth.newMilestones, isEmpty);
    });

    test('al llegar a 7 días se reporta milestone 7', () async {
      await bumpDays(6); // streak = 6
      final seventh = await StreakService().updateStreak(userId);
      expect(seventh.streak.currentStreak, 7);
      expect(seventh.newMilestones, equals([7]));
    });

    test('al llegar a 30 días se reporta milestone 30', () async {
      await bumpDays(29); // streak = 29
      final thirtieth = await StreakService().updateStreak(userId);
      expect(thirtieth.streak.currentStreak, 30);
      expect(thirtieth.newMilestones, equals([30]));
    });

    test('después de un reset, los milestones previos no se redisparan', () async {
      await bumpDays(3); // hits milestone 3
      // Saltar varios días para resetear.
      clock = clock.add(const Duration(days: 5));
      final afterReset = await StreakService().updateStreak(userId);
      expect(afterReset.streak.currentStreak, 1);
      expect(afterReset.newMilestones, isEmpty);

      // Volver a llegar a 3 → milestone 3 NO se redispara (ya está en
      // milestonesReached por diseño — evita spam de notificaciones).
      clock = clock.add(const Duration(days: 1));
      await StreakService().updateStreak(userId); // streak=2
      clock = clock.add(const Duration(days: 1));
      final thirdAgain = await StreakService().updateStreak(userId);
      expect(thirdAgain.streak.currentStreak, 3);
      expect(thirdAgain.newMilestones, isEmpty);
    });
  });
}
