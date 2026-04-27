import '../core/utils/logger.dart';
import '../data/repositories/streak_repository_impl.dart';
import '../domain/entities/streak_entity.dart';
import '../domain/repositories/streak_repository.dart';

/// Result of an `updateStreak` call. Tells the UI whether anything changed
/// and surfaces any milestones that were just reached so the caller can
/// trigger celebrations / notifications.
class StreakUpdateResult {
  const StreakUpdateResult({
    required this.streak,
    required this.changed,
    required this.newMilestones,
  });

  final StreakEntity streak;

  /// True when the persisted streak changed (incremented, reset, or new).
  /// False when the user already had activity today and nothing was written.
  final bool changed;

  /// Milestones reached as a result of *this* update — typically a 0- or
  /// 1-element list. Empty when no milestone was crossed.
  final List<int> newMilestones;
}

/// Singleton facade over [StreakRepository].
///
/// Encapsulates the streak progression rules so screens never have to think
/// about day boundaries or milestone bookkeeping.
class StreakService {
  StreakService._internal();
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;

  /// Day-counts that trigger a celebration. Values must be sorted ascending.
  static const List<int> milestones = [3, 7, 14, 30];

  // Lazy: instanciar StreakRepositoryImpl tocaría FirebaseFirestore.instance,
  // lo que falla en tests sin Firebase inicializado. Esperamos al primer uso.
  StreakRepository? _repositoryOverride;
  StreakRepository get _repository =>
      _repositoryOverride ??= StreakRepositoryImpl();

  DateTime Function() _now = DateTime.now;

  /// Test seam — replace the repository and clock for unit tests.
  void debugOverride({
    StreakRepository? repository,
    DateTime Function()? now,
  }) {
    if (repository != null) _repositoryOverride = repository;
    if (now != null) _now = now;
  }

  Stream<StreakEntity?> watch(String userId) =>
      _repository.watchStreak(userId);

  Future<StreakEntity?> get(String userId) => _repository.getStreak(userId);

  /// Records a qualifying activity for [userId] (e.g. completing an exercise
  /// session). Idempotent within a single calendar day.
  Future<StreakUpdateResult> updateStreak(String userId) async {
    final today = _dayOnly(_now());
    final existing =
        await _repository.getStreak(userId) ?? StreakEntity.empty(userId);

    final lastDay = existing.lastActivityDate == null
        ? null
        : _dayOnly(existing.lastActivityDate!);

    if (lastDay != null && lastDay.isAtSameMomentAs(today)) {
      // Already counted today; no-op.
      return StreakUpdateResult(
        streak: existing,
        changed: false,
        newMilestones: const [],
      );
    }

    final int newCurrent;
    if (lastDay == null) {
      newCurrent = 1;
    } else {
      final diff = today.difference(lastDay).inDays;
      newCurrent = diff == 1 ? existing.currentStreak + 1 : 1;
    }

    final newLongest =
        newCurrent > existing.longestStreak ? newCurrent : existing.longestStreak;

    final newMilestones = milestones
        .where((m) =>
            newCurrent >= m && !existing.milestonesReached.contains(m))
        .toList();

    final updated = existing.copyWith(
      currentStreak: newCurrent,
      longestStreak: newLongest,
      lastActivityDate: today,
      milestonesReached: [
        ...existing.milestonesReached,
        ...newMilestones,
      ],
    );

    await _repository.saveStreak(updated);

    if (newMilestones.isNotEmpty) {
      AppLogger.info(
        'Streak milestone(s) reached: $newMilestones',
        tag: 'Streak',
      );
    }

    return StreakUpdateResult(
      streak: updated,
      changed: true,
      newMilestones: newMilestones,
    );
  }

  /// Strips time-of-day so we only compare calendar days.
  DateTime _dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
