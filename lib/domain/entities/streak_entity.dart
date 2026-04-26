/// User streak: how many consecutive days the user has logged at least one
/// exercise session.
///
/// `lastActivityDate` is normalized to the local-day boundary (no time of
/// day) so equality/comparison checks operate at day granularity.
class StreakEntity {
  const StreakEntity({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityDate,
    this.milestonesReached = const <int>[],
  });

  factory StreakEntity.empty(String userId) => StreakEntity(
        userId: userId,
        currentStreak: 0,
        longestStreak: 0,
        lastActivityDate: null,
      );

  final String userId;
  final int currentStreak;
  final int longestStreak;

  /// Day of the user's most recent qualifying activity (no time component).
  /// Null when the user has never had a streak.
  final DateTime? lastActivityDate;

  /// Milestone day-counts that have already triggered a celebration.
  /// Keeping this list prevents re-triggering when the user views the streak
  /// again on the same day.
  final List<int> milestonesReached;

  StreakEntity copyWith({
    String? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    List<int>? milestonesReached,
    bool clearLastActivity = false,
  }) {
    return StreakEntity(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate:
          clearLastActivity ? null : (lastActivityDate ?? this.lastActivityDate),
      milestonesReached: milestonesReached ?? this.milestonesReached,
    );
  }
}
