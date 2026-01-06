import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/exercise_entity.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../../core/constants/api_constants.dart';

/// Firebase implementation of ExerciseRepository
class ExerciseRepositoryImpl implements ExerciseRepository {
  final FirebaseFirestore _firestore;

  ExerciseRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _exercisesCollection =>
      _firestore.collection(ApiConstants.exercisesCollection);

  @override
  Future<List<ExerciseEntity>> getAllExercises() async {
    final snapshot = await _exercisesCollection.get();
    return snapshot.docs.map(_mapToEntity).toList();
  }

  @override
  Future<ExerciseEntity?> getExerciseById(String exerciseId) async {
    final doc = await _exercisesCollection.doc(exerciseId).get();
    if (!doc.exists) return null;
    return _mapToEntity(doc);
  }

  @override
  Future<List<ExerciseEntity>> getExercisesByCategory(String category) async {
    final snapshot = await _exercisesCollection
        .where('categories', arrayContains: category)
        .get();
    return snapshot.docs.map(_mapToEntity).toList();
  }

  @override
  Future<List<ExerciseEntity>> getExercisesByDifficulty(String difficulty) async {
    final snapshot = await _exercisesCollection
        .where('difficulty', isEqualTo: difficulty)
        .get();
    return snapshot.docs.map(_mapToEntity).toList();
  }

  @override
  Future<List<ExerciseEntity>> getUserExercises(String userId) async {
    final userDoc = await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .get();
    
    final assignedExercises = userDoc.data()?['assignedExercises'] as List<dynamic>? ?? [];
    
    if (assignedExercises.isEmpty) {
      return getAllExercises();
    }
    
    final exercises = <ExerciseEntity>[];
    for (final exerciseId in assignedExercises) {
      final exercise = await getExerciseById(exerciseId as String);
      if (exercise != null) exercises.add(exercise);
    }
    return exercises;
  }

  @override
  Future<List<ExerciseEntity>> searchExercises(String query) async {
    final allExercises = await getAllExercises();
    final queryLower = query.toLowerCase();
    
    return allExercises.where((exercise) {
      return exercise.title.toLowerCase().contains(queryLower) ||
             exercise.description.toLowerCase().contains(queryLower) ||
             exercise.targetMuscles.toLowerCase().contains(queryLower) ||
             exercise.categories.any((c) => c.toLowerCase().contains(queryLower));
    }).toList();
  }

  @override
  Future<void> saveExerciseProgress({
    required String userId,
    required String exerciseId,
    required int completedReps,
    required int totalReps,
    required Duration duration,
    int? painLevel,
    String? notes,
  }) async {
    await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.progressCollection)
        .add({
          'exerciseId': exerciseId,
          'completedReps': completedReps,
          'totalReps': totalReps,
          'durationSeconds': duration.inSeconds,
          'painLevel': painLevel,
          'notes': notes,
          'completedAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  Future<List<Map<String, dynamic>>> getExerciseHistory(String userId) async {
    final snapshot = await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.progressCollection)
        .orderBy('completedAt', descending: true)
        .limit(50)
        .get();
    
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  @override
  Future<Map<String, dynamic>> getWeeklyStats(String userId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final snapshot = await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.progressCollection)
        .where('completedAt', isGreaterThan: Timestamp.fromDate(weekAgo))
        .get();
    
    int totalSessions = snapshot.docs.length;
    int totalReps = 0;
    int totalSeconds = 0;
    
    for (final doc in snapshot.docs) {
      totalReps += (doc.data()['completedReps'] as int? ?? 0);
      totalSeconds += (doc.data()['durationSeconds'] as int? ?? 0);
    }
    
    return {
      'totalSessions': totalSessions,
      'totalReps': totalReps,
      'totalDuration': Duration(seconds: totalSeconds),
      'avgSessionDuration': totalSessions > 0 
          ? Duration(seconds: totalSeconds ~/ totalSessions) 
          : Duration.zero,
    };
  }

  // ============ Mapping helpers ============

  ExerciseEntity _mapToEntity(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ExerciseEntity(
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
}
