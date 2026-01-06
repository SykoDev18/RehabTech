/// Routine entity for exercise routines
class RoutineEntity {
  final String id;
  final String name;
  final String patientId;
  final String patientName;
  final String therapistId;
  final List<RoutineExerciseEntity> exercises;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RoutineEntity({
    required this.id,
    required this.name,
    required this.patientId,
    required this.patientName,
    required this.therapistId,
    this.exercises = const [],
    required this.createdAt,
    this.updatedAt,
  });

  int get exerciseCount => exercises.length;

  RoutineEntity copyWith({
    String? id,
    String? name,
    String? patientId,
    String? patientName,
    String? therapistId,
    List<RoutineExerciseEntity>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoutineEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      therapistId: therapistId ?? this.therapistId,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoutineEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Exercise within a routine
class RoutineExerciseEntity {
  final String id;
  final String name;
  final String? description;
  final String? instructions;
  final String? videoUrl;
  final String? imageUrl;
  final int series;
  final int reps;
  final int? durationSeconds;
  final int order;

  const RoutineExerciseEntity({
    required this.id,
    required this.name,
    this.description,
    this.instructions,
    this.videoUrl,
    this.imageUrl,
    required this.series,
    required this.reps,
    this.durationSeconds,
    this.order = 0,
  });

  String get formattedSetsReps => '$series series × $reps reps';
  
  String? get formattedDuration {
    if (durationSeconds == null) return null;
    final mins = durationSeconds! ~/ 60;
    final secs = durationSeconds! % 60;
    if (mins > 0 && secs > 0) return '${mins}m ${secs}s';
    if (mins > 0) return '${mins}m';
    return '${secs}s';
  }

  RoutineExerciseEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? instructions,
    String? videoUrl,
    String? imageUrl,
    int? series,
    int? reps,
    int? durationSeconds,
    int? order,
  }) {
    return RoutineExerciseEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      series: series ?? this.series,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoutineExerciseEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
