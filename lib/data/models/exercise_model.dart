import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/exercise_entity.dart';

/// Exercise model (DTO) for data layer
class ExerciseModel {
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

  const ExerciseModel({
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

  /// Create from Firestore document
  factory ExerciseModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ExerciseModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      duration: data['duration'] ?? '15 min',
      series: data['series'] ?? 3,
      reps: data['reps'] ?? 10,
      instructions: List<String>.from(data['instructions'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
      iconName: data['iconName'] ?? 'activity',
      iconColorValue: data['iconColorValue'] ?? 0xFF2563EB,
      iconBgColorValue: data['iconBgColorValue'] ?? 0xFFDBEAFE,
      categories: List<String>.from(data['categories'] ?? []),
      difficulty: data['difficulty'] ?? 'Fácil',
      targetMuscles: data['targetMuscles'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Create from JSON
  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? '15 min',
      series: json['series'] ?? 3,
      reps: json['reps'] ?? 10,
      instructions: List<String>.from(json['instructions'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      iconName: json['iconName'] ?? 'activity',
      iconColorValue: json['iconColorValue'] ?? 0xFF2563EB,
      iconBgColorValue: json['iconBgColorValue'] ?? 0xFFDBEAFE,
      categories: List<String>.from(json['categories'] ?? []),
      difficulty: json['difficulty'] ?? 'Fácil',
      targetMuscles: json['targetMuscles'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'duration': duration,
      'series': series,
      'reps': reps,
      'instructions': instructions,
      'imageUrl': imageUrl,
      'iconName': iconName,
      'iconColorValue': iconColorValue,
      'iconBgColorValue': iconBgColorValue,
      'categories': categories,
      'difficulty': difficulty,
      'targetMuscles': targetMuscles,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration': duration,
      'series': series,
      'reps': reps,
      'instructions': instructions,
      'imageUrl': imageUrl,
      'iconName': iconName,
      'iconColorValue': iconColorValue,
      'iconBgColorValue': iconBgColorValue,
      'categories': categories,
      'difficulty': difficulty,
      'targetMuscles': targetMuscles,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity
  ExerciseEntity toEntity() {
    return ExerciseEntity(
      id: id,
      title: title,
      description: description,
      duration: duration,
      series: series,
      reps: reps,
      instructions: instructions,
      imageUrl: imageUrl,
      iconName: iconName,
      iconColorValue: iconColorValue,
      iconBgColorValue: iconBgColorValue,
      categories: categories,
      difficulty: difficulty,
      targetMuscles: targetMuscles,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory ExerciseModel.fromEntity(ExerciseEntity entity) {
    return ExerciseModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      duration: entity.duration,
      series: entity.series,
      reps: entity.reps,
      instructions: entity.instructions,
      imageUrl: entity.imageUrl,
      iconName: entity.iconName,
      iconColorValue: entity.iconColorValue,
      iconBgColorValue: entity.iconBgColorValue,
      categories: entity.categories,
      difficulty: entity.difficulty,
      targetMuscles: entity.targetMuscles,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
