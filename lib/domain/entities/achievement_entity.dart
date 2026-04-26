/// Catalog entry for an achievement (badge). Definitions live in
/// `domain/constants/achievement_catalog.dart` — there is no Firestore
/// catalog write path; updating the catalog requires an app release.
class AchievementEntity {
  const AchievementEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.condition,
    required this.points,
  });

  final String id;
  final String title;
  final String description;

  /// String identifier resolved to a Lucide icon by the UI layer. Keeping
  /// this as a string keeps the domain layer free of Flutter dependencies.
  final String iconName;

  /// Human-readable description of how to unlock this achievement (Spanish).
  final String condition;

  final int points;
}
