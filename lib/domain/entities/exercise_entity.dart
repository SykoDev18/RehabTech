/// Exercise entity representing an exercise in the domain layer
class ExerciseEntity {
  final String id;
  final String title;
  final String description;
  final String duration;
  final int series;
  final int reps;
  final List<String> instructions;
  final String imageUrl;
  final String iconName;
  final int iconColorValue;
  final int iconBgColorValue;
  final List<String> categories;
  final String difficulty;
  final String targetMuscles;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExerciseEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.series,
    required this.reps,
    required this.instructions,
    required this.imageUrl,
    this.iconName = 'activity',
    this.iconColorValue = 0xFF2563EB,
    this.iconBgColorValue = 0xFFDBEAFE,
    required this.categories,
    required this.difficulty,
    required this.targetMuscles,
    this.createdAt,
    this.updatedAt,
  });

  bool get isEasy => difficulty.toLowerCase() == 'fácil';
  bool get isMedium => difficulty.toLowerCase() == 'medio';
  bool get isHard => difficulty.toLowerCase() == 'difícil';

  String get formattedDuration {
    if (duration.contains('min')) return duration;
    return '$duration min';
  }

  String get totalReps => '${series}x$reps';

  ExerciseEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? duration,
    int? series,
    int? reps,
    List<String>? instructions,
    String? imageUrl,
    String? iconName,
    int? iconColorValue,
    int? iconBgColorValue,
    List<String>? categories,
    String? difficulty,
    String? targetMuscles,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExerciseEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      series: series ?? this.series,
      reps: reps ?? this.reps,
      instructions: instructions ?? this.instructions,
      imageUrl: imageUrl ?? this.imageUrl,
      iconName: iconName ?? this.iconName,
      iconColorValue: iconColorValue ?? this.iconColorValue,
      iconBgColorValue: iconBgColorValue ?? this.iconBgColorValue,
      categories: categories ?? this.categories,
      difficulty: difficulty ?? this.difficulty,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
