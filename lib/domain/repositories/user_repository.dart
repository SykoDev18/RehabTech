import '../entities/user_entity.dart';

/// User repository interface for user data operations
abstract class UserRepository {
  /// Get user by ID
  Future<UserEntity?> getUserById(String userId);
  
  /// Get current user profile
  Future<UserEntity?> getCurrentUser();
  
  /// Create user profile
  Future<void> createUser(UserEntity user);
  
  /// Update user profile
  Future<void> updateUser(UserEntity user);
  
  /// Delete user profile
  Future<void> deleteUser(String userId);
  
  /// Stream of user changes
  Stream<UserEntity?> watchUser(String userId);
  
  /// Update user photo
  Future<String> uploadUserPhoto(String userId, String filePath);
  
  /// Get therapist by ID
  Future<UserEntity?> getTherapist(String therapistId);
  
  /// Get all therapists
  Future<List<UserEntity>> getAllTherapists();
  
  /// Assign therapist to patient
  Future<void> assignTherapist(String patientId, String therapistId);
}
