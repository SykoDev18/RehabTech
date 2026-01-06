import '../entities/exercise_entity.dart';

/// Exercise repository interface
abstract class ExerciseRepository {
  /// Get all exercises
  Future<List<ExerciseEntity>> getAllExercises();
  
  /// Get exercise by ID
  Future<ExerciseEntity?> getExerciseById(String exerciseId);
  
  /// Get exercises by category
  Future<List<ExerciseEntity>> getExercisesByCategory(String category);
  
  /// Get exercises by difficulty
  Future<List<ExerciseEntity>> getExercisesByDifficulty(String difficulty);
  
  /// Get user's assigned exercises
  Future<List<ExerciseEntity>> getUserExercises(String userId);
  
  /// Search exercises
  Future<List<ExerciseEntity>> searchExercises(String query);
  
  /// Save exercise progress
  Future<void> saveExerciseProgress({
    required String userId,
    required String exerciseId,
    required int completedReps,
    required int totalReps,
    required Duration duration,
    int? painLevel,
    String? notes,
  });
  
  /// Get exercise history for user
  Future<List<Map<String, dynamic>>> getExerciseHistory(String userId);
  
  /// Get weekly progress stats
  Future<Map<String, dynamic>> getWeeklyStats(String userId);
}
